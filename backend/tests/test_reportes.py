"""Tests del servicio de reportes (estadísticas, CSV y PDF)."""
import csv
import datetime
import io

import pytest

from common.models import Causa, CausaParte, Documento, Movimiento, Parte, Tribunal, Usuario
from conftest import auth_header, load_service

svc = load_service("reportes")
H = auth_header("ADMINISTRADOR")
HOY = datetime.date.today()


def _dt(dias):
    return datetime.datetime.combine(HOY + datetime.timedelta(days=dias), datetime.time(10))


@pytest.fixture
def client(db):
    db.add_all([
        Tribunal(id_tribunal=1, nombre="Juzgado Civil"),
        Tribunal(id_tribunal=2, nombre="Juzgado Laboral"),
        Usuario(id_usuario=1, nombre="Ana Abogada", correo="ana@j.cl", password_hash="x", rol="ABOGADO"),
        Causa(id_causa=1, rit="C-1", tribunal_id=1, fecha_inicio=datetime.date(2024, 1, 1), estado="ACTIVA"),
        Causa(id_causa=2, rit="L-2", tribunal_id=2, fecha_inicio=datetime.date(2024, 2, 1), estado="ARCHIVADA"),
        Parte(id_parte=1, nombre="Cliente", tipo="DEMANDANTE"),
        CausaParte(id_causa=1, id_parte=1, representado_por=1),
        Documento(id_causa=1, tipo="OFICIO", nombre_archivo="oficio.pdf", ruta_storage="/x/oficio.pdf"),
        Movimiento(id_causa=1, fecha=_dt(-5), descripcion="Audiencia", tipo="AUDIENCIA"),
        Movimiento(id_causa=1, fecha=_dt(-60), descripcion="Antigua", tipo="OTRO"),
        Movimiento(id_causa=1, fecha=_dt(10), descripcion="Plazo prueba", tipo="VENCIMIENTO"),
        Movimiento(id_causa=2, fecha=_dt(45), descripcion="Plazo lejano", tipo="VENCIMIENTO"),
        Movimiento(id_causa=2, fecha=_dt(-1), descripcion="Plazo vencido", tipo="VENCIMIENTO"),
    ])
    db.commit()
    return svc.app.test_client()


def _csv(resp):
    assert resp.status_code == 200
    assert resp.mimetype == "text/csv"
    return list(csv.DictReader(io.StringIO(resp.get_data(as_text=True))))


def test_estadisticas(client):
    data = client.get("/estadisticas", headers=H).get_json()
    assert data["casos"] == {"total": 2, "activos": 1}
    assert data["documentos_total"] == 1
    # Solo cuentan los movimientos con fecha en los últimos 30 días (incluye futuros).
    assert data["movimientos_ultimos_30_dias"] == 4


def test_reporte_casos_completo(client):
    filas = {f["rit"]: f for f in _csv(client.get("/casos", headers=H))}
    assert set(filas) == {"C-1", "L-2"}
    assert filas["C-1"]["abogado_responsable"] == "Ana Abogada"
    assert filas["L-2"]["abogado_responsable"] == "N/A"
    assert filas["L-2"]["tribunal"] == "Juzgado Laboral"


def test_reporte_casos_filtra_por_tribunal_y_abogado(client):
    assert [f["rit"] for f in _csv(client.get("/casos?tribunal_id=2", headers=H))] == ["L-2"]
    assert [f["rit"] for f in _csv(client.get("/casos?abogado_id=1", headers=H))] == ["C-1"]


def test_reporte_vencimientos_solo_proximos_30_dias(client):
    filas = _csv(client.get("/vencimientos", headers=H))
    assert [f["descripcion_vencimiento"] for f in filas] == ["Plazo prueba"]
    assert filas[0]["causa_rit"] == "C-1"


def test_historial_pdf(client):
    resp = client.get("/causa-history/C-1/pdf", headers=H)
    assert resp.status_code == 200
    assert resp.headers["Content-Type"] == "application/pdf"
    assert resp.data.startswith(b"%PDF")
    assert "historial_causa_C-1.pdf" in resp.headers["Content-Disposition"]


def test_historial_pdf_causa_inexistente(client):
    assert client.get("/causa-history/NO-EXISTE/pdf", headers=H).status_code == 404


def test_reportes_exigen_token(client):
    for ruta in ("/estadisticas", "/casos", "/vencimientos", "/causa-history/C-1/pdf"):
        assert client.get(ruta).status_code == 401


def test_tribunales_y_health_publicos(client):
    assert len(client.get("/tribunales").get_json()) == 2
    assert client.get("/health").get_json() == {"status": "healthy"}
