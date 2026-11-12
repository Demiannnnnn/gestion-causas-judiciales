"""Tests del servicio de notificaciones (envío, vencimientos, resumen y consultas)."""
import datetime
from unittest import mock

import pytest

from common.models import Causa, CausaParte, Movimiento, Notificacion, Parte, Tribunal, Usuario
from conftest import auth_header, load_service

svc = load_service("notificaciones")


@pytest.fixture
def smtp():
    with mock.patch.object(svc.smtplib, "SMTP") as smtp_cls:
        yield smtp_cls


@pytest.fixture
def client(db, smtp):
    db.add(Usuario(id_usuario=1, nombre="Ana", correo="ana@judicial.cl", password_hash="x", rol="ABOGADO"))
    db.add(Usuario(id_usuario=2, nombre="Beto", correo="beto@judicial.cl", password_hash="x", rol="ABOGADO"))
    db.commit()
    return svc.app.test_client()


# --- enviar_email ---------------------------------------------------------

def test_enviar_email_sin_credenciales_no_usa_tls(smtp):
    assert svc.enviar_email("a@b.cl", "Asunto", "Hola") is True
    server = smtp.return_value.__enter__.return_value
    server.starttls.assert_not_called()
    msg = server.send_message.call_args.args[0]
    assert msg["To"] == "a@b.cl"
    assert msg["Subject"] == "Asunto"


def test_enviar_email_con_credenciales_hace_login(smtp, monkeypatch):
    monkeypatch.setattr(svc, "SMTP_USER", "user")
    monkeypatch.setattr(svc, "SMTP_PASSWORD", "pass")
    assert svc.enviar_email("a@b.cl", "s", "<b>x</b>", html=True) is True
    server = smtp.return_value.__enter__.return_value
    server.starttls.assert_called_once()
    server.login.assert_called_once_with("user", "pass")
    msg = server.send_message.call_args.args[0]
    assert msg.get_payload()[0].get_content_subtype() == "html"


def test_enviar_email_devuelve_false_si_falla_smtp(smtp):
    smtp.side_effect = OSError("sin conexión")
    assert svc.enviar_email("a@b.cl", "s", "m") is False


# --- /send ------------------------------------------------------------------

def test_send_guarda_notificacion_enviada_y_asocia_usuario(client, db):
    resp = client.post("/send", json={
        "tipo": "MOVIMIENTO", "caso_rit": "C-1", "destinatario": "ana@judicial.cl",
        "asunto": "Nuevo movimiento", "mensaje": "Detalle",
    })
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["success"] is True
    assert data["notificacion"]["estado"] == "ENVIADA"
    assert data["notificacion"]["id_usuario"] == 1


def test_send_marca_error_si_no_se_pudo_enviar(client, smtp):
    smtp.side_effect = OSError("caído")
    resp = client.post("/send", json={
        "tipo": "ALERTA", "destinatario": "externo@x.cl", "asunto": "a", "mensaje": "m",
    })
    data = resp.get_json()
    assert data["success"] is False
    assert data["notificacion"]["estado"] == "ERROR"
    assert data["notificacion"]["id_usuario"] is None
    assert data["notificacion"]["caso_rit"] == "N/A"


@pytest.mark.parametrize("faltante", ["tipo", "destinatario", "asunto", "mensaje"])
def test_send_valida_campos_requeridos(client, faltante):
    body = {"tipo": "ALERTA", "destinatario": "a@b.cl", "asunto": "a", "mensaje": "m"}
    del body[faltante]
    resp = client.post("/send", json=body)
    assert resp.status_code == 400
    assert faltante in resp.get_json()["error"]


# --- /vencimientos ----------------------------------------------------------

def _causa_con_vencimiento(db, dias):
    db.add(Tribunal(id_tribunal=1, nombre="Juzgado"))
    db.add(Causa(id_causa=1, rit="C-9-2024", tribunal_id=1))
    db.add(Parte(id_parte=1, nombre="Cliente", tipo="DEMANDANTE"))
    db.add(CausaParte(id_causa=1, id_parte=1, representado_por=1))
    fecha = datetime.datetime.combine(datetime.date.today() + datetime.timedelta(days=dias), datetime.time(9))
    db.add(Movimiento(id_causa=1, fecha=fecha, descripcion="Contestar demanda", tipo="VENCIMIENTO"))
    db.commit()


def test_vencimientos_sin_movimientos(client):
    resp = client.post("/vencimientos")
    assert resp.status_code == 200
    assert "No se encontraron" in resp.get_json()["message"]


def test_vencimientos_crea_una_notificacion_por_abogado_sin_duplicar(client, db):
    _causa_con_vencimiento(db, dias=3)
    assert client.post("/vencimientos").status_code == 200
    assert client.post("/vencimientos").status_code == 200  # segunda ejecución: idempotente
    notifs = db.query(Notificacion).all()
    assert len(notifs) == 1
    assert notifs[0].destinatario == "ana@judicial.cl"
    assert notifs[0].tipo == "VENCIMIENTO"
    assert notifs[0].estado == "PENDIENTE"
    assert "Contestar demanda" in notifs[0].mensaje


def test_vencimientos_ignora_plazos_fuera_de_7_dias(client, db):
    _causa_con_vencimiento(db, dias=20)
    client.post("/vencimientos")
    assert db.query(Notificacion).count() == 0


# --- /resumen-diario --------------------------------------------------------

def test_resumen_diario_envia_y_marca_como_leidas(client, db, smtp):
    db.add(Notificacion(id_usuario=1, tipo="ALERTA", destinatario="ana@judicial.cl", asunto="Uno",
                        mensaje="m1", fecha_envio=datetime.datetime(2024, 1, 1, 8, 0), leido=False))
    db.commit()
    assert client.post("/resumen-diario").status_code == 200
    server = smtp.return_value.__enter__.return_value
    assert server.send_message.call_count == 1  # solo Ana tiene pendientes
    db.expire_all()
    assert db.query(Notificacion).one().leido is True


def test_resumen_diario_no_marca_si_falla_el_envio(client, db, smtp):
    db.add(Notificacion(id_usuario=1, tipo="ALERTA", destinatario="ana@judicial.cl", asunto="Uno",
                        mensaje="m1", fecha_envio=datetime.datetime(2024, 1, 1, 8, 0), leido=False))
    db.commit()
    smtp.side_effect = OSError("caído")
    client.post("/resumen-diario")
    db.expire_all()
    assert db.query(Notificacion).one().leido is False


# --- consultas del usuario ----------------------------------------------------

@pytest.fixture
def con_notificaciones(db):
    db.add_all([
        Notificacion(id_notificacion=1, id_usuario=1, tipo="ALERTA", destinatario="ana@judicial.cl",
                     asunto="a", mensaje="m", estado="ENVIADA", leido=False,
                     fecha_envio=datetime.datetime(2024, 1, 1)),
        Notificacion(id_notificacion=2, id_usuario=1, tipo="VENCIMIENTO", destinatario="ana@judicial.cl",
                     asunto="b", mensaje="m", estado="ERROR", leido=True,
                     fecha_envio=datetime.datetime(2024, 2, 1)),
        Notificacion(id_notificacion=3, id_usuario=2, tipo="ALERTA", destinatario="beto@judicial.cl",
                     asunto="c", mensaje="m", estado="ENVIADA", leido=False,
                     fecha_envio=datetime.datetime(2024, 3, 1)),
    ])
    db.commit()


def test_listar_solo_las_del_usuario_ordenadas(client, con_notificaciones):
    data = client.get("/", headers=auth_header(id_usuario=1)).get_json()
    assert [n["id"] for n in data] == [2, 1]


def test_listar_filtra_por_tipo_y_leido(client, con_notificaciones):
    h = auth_header(id_usuario=1)
    assert [n["id"] for n in client.get("/?tipo=ALERTA", headers=h).get_json()] == [1]
    assert [n["id"] for n in client.get("/?leido=true", headers=h).get_json()] == [2]
    assert [n["id"] for n in client.get("/?leido=false", headers=h).get_json()] == [1]


def test_marcar_leido_solo_propias(client, db, con_notificaciones):
    assert client.put("/3/marcar-leido", headers=auth_header(id_usuario=1)).status_code == 404
    resp = client.put("/1/marcar-leido", headers=auth_header(id_usuario=1))
    assert resp.status_code == 200
    assert resp.get_json()["leido"] is True


def test_eliminar_solo_propias(client, db, con_notificaciones):
    assert client.delete("/3", headers=auth_header(id_usuario=1)).status_code == 404
    assert client.delete("/1", headers=auth_header(id_usuario=1)).status_code == 200
    db.expire_all()
    assert db.get(Notificacion, 1) is None


def test_stats_cuenta_por_estado_y_lectura(client, con_notificaciones):
    data = client.get("/stats").get_json()
    assert data == {"total": 3, "enviadas": 2, "errores": 1, "leidas": 1, "no_leidas": 2}


def test_health(client):
    assert client.get("/health").get_json()["service"] == "notificaciones"
