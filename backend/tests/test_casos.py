"""Tests del servicio de causas (CRUD de causas y movimientos)."""
import datetime
from unittest import mock

import pytest

from common.models import Causa, CausaParte, Movimiento, Parte, Tribunal, Usuario
from conftest import auth_header, load_service

svc = load_service("casos")


@pytest.fixture
def notificaciones():
    """Evita llamadas HTTP reales al servicio de notificaciones."""
    with mock.patch.object(svc.requests, "post") as post:
        yield post


@pytest.fixture
def client(db, notificaciones):
    db.add(Tribunal(id_tribunal=1, nombre="1er Juzgado Civil de Santiago"))
    db.add(Causa(id_causa=10, rit="C-100-2024", tribunal_id=1,
                 fecha_inicio=datetime.date(2024, 1, 15), estado="ACTIVA", descripcion="Cobro"))
    db.commit()
    return svc.app.test_client()


H = auth_header("ABOGADO")


def test_rutas_protegidas_exigen_token(client):
    assert client.get("/").status_code == 401
    assert client.post("/", json={"rit": "x", "tribunal_id": 1}).status_code == 401
    assert client.delete("/10").status_code == 401


def test_tribunales_es_publico(client):
    resp = client.get("/tribunales")
    assert resp.status_code == 200
    assert resp.get_json() == [{"id_tribunal": 1, "nombre": "1er Juzgado Civil de Santiago"}]


def test_listar_y_obtener_caso(client):
    lista = client.get("/", headers=H).get_json()
    assert [c["rit"] for c in lista] == ["C-100-2024"]
    caso = client.get("/10", headers=H).get_json()
    assert caso["fecha_inicio"] == "2024-01-15"
    assert client.get("/999", headers=H).status_code == 404


def test_crear_caso_parsea_fecha_y_notifica(client, db, notificaciones):
    resp = client.post("/", headers=H, json={
        "rit": "C-200-2024", "tribunal_id": 1, "fecha_inicio": "2024-05-02", "descripcion": "Nuevo",
    })
    assert resp.status_code == 201
    creado = db.get(Causa, resp.get_json()["id_causa"])
    assert creado.fecha_inicio == datetime.date(2024, 5, 2)
    assert creado.estado == "ACTIVA"
    url = notificaciones.call_args.args[0]
    body = notificaciones.call_args.kwargs["json"]
    assert url.endswith("/send")
    assert body["caso_rit"] == "C-200-2024"


@pytest.mark.parametrize("fecha", [None, "02/05/2024"])
def test_crear_caso_sin_fecha_o_fecha_invalida_usa_hoy(client, db, fecha):
    body = {"rit": f"C-{fecha}", "tribunal_id": 1}
    if fecha:
        body["fecha_inicio"] = fecha
    resp = client.post("/", headers=H, json=body)
    assert resp.status_code == 201
    assert db.get(Causa, resp.get_json()["id_causa"]).fecha_inicio == datetime.date.today()


def test_crear_caso_con_rit_duplicado_devuelve_409(client):
    resp = client.post("/", headers=H, json={"rit": "C-100-2024", "tribunal_id": 1})
    assert resp.status_code == 409


def test_crear_caso_no_falla_si_notificaciones_no_responde(client, notificaciones):
    notificaciones.side_effect = ConnectionError("caído")
    resp = client.post("/", headers=H, json={"rit": "C-300-2024", "tribunal_id": 1})
    assert resp.status_code == 201


def test_actualizar_caso(client, db):
    resp = client.put("/10", headers=H, json={"estado": "ARCHIVADA"})
    assert resp.status_code == 200
    db.expire_all()
    caso = db.get(Causa, 10)
    assert caso.estado == "ARCHIVADA"
    assert caso.rit == "C-100-2024"  # los campos no enviados se conservan
    assert client.put("/999", headers=H, json={}).status_code == 404


def test_eliminar_caso(client, db):
    assert client.delete("/10", headers=H).status_code == 200
    db.expire_all()
    assert db.get(Causa, 10) is None
    assert client.delete("/10", headers=H).status_code == 404


def test_partes_de_un_caso(client, db):
    db.add(Usuario(id_usuario=3, nombre="Abogada Pérez", correo="p@j.cl", password_hash="x", rol="ABOGADO"))
    db.add(Parte(id_parte=1, nombre="Juan Soto", tipo="DEMANDANTE", rut="11.111.111-1"))
    db.add(Parte(id_parte=2, nombre="Empresa SpA", tipo="DEMANDADO"))
    db.add(CausaParte(id_causa=10, id_parte=1, representado_por=3))
    db.add(CausaParte(id_causa=10, id_parte=2))
    db.commit()
    partes = {p["nombre"]: p for p in client.get("/10/partes", headers=H).get_json()}
    assert partes["Juan Soto"]["representante"] == "Abogada Pérez"
    assert partes["Empresa SpA"]["representante"] is None
    assert client.get("/999/partes", headers=H).status_code == 404


def test_crear_y_listar_movimientos(client, db, notificaciones):
    resp = client.post("/10/movimientos", headers=H, json={
        "fecha": "2024-06-01", "descripcion": "Audiencia preparatoria", "tipo": "AUDIENCIA",
    })
    assert resp.status_code == 201
    movs = client.get("/10/movimientos", headers=H).get_json()
    assert len(movs) == 1
    assert movs[0]["tipo"] == "AUDIENCIA"
    assert movs[0]["fecha"].startswith("2024-06-01")
    # Un movimiento normal solo notifica por /send.
    assert [c.args[0].rsplit("/", 1)[-1] for c in notificaciones.call_args_list] == ["send"]


def test_movimiento_vencimiento_dispara_revision_de_vencimientos(client, notificaciones):
    resp = client.post("/10/movimientos", headers=H, json={
        "fecha": "2024-06-01", "descripcion": "Plazo para contestar", "tipo": "VENCIMIENTO",
    })
    assert resp.status_code == 201
    destinos = [c.args[0].rsplit("/", 1)[-1] for c in notificaciones.call_args_list]
    assert destinos == ["send", "vencimientos"]


def test_movimiento_con_fecha_invalida_devuelve_400(client, db):
    resp = client.post("/10/movimientos", headers=H, json={
        "fecha": "01-06-2024", "descripcion": "x", "tipo": "OTRO",
    })
    assert resp.status_code == 400
    assert db.query(Movimiento).count() == 0


def test_movimiento_en_caso_inexistente_devuelve_404(client):
    resp = client.post("/999/movimientos", headers=H, json={"descripcion": "x", "tipo": "OTRO"})
    assert resp.status_code == 404
