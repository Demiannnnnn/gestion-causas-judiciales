"""Tests del servicio de documentos (subida, listado, descarga y borrado)."""
import datetime
import io
import os

import pytest

from common.models import Causa, Documento, Tribunal
from conftest import auth_header, load_service

svc = load_service("documentos")
H = auth_header("ASISTENTE", id_usuario=7)


@pytest.fixture
def client(db, tmp_path):
    db.add(Tribunal(id_tribunal=1, nombre="Juzgado"))
    db.add(Causa(id_causa=1, rit="C-1-2024", tribunal_id=1, fecha_inicio=datetime.date(2024, 1, 1)))
    db.commit()
    svc.app.config["UPLOAD_FOLDER"] = str(tmp_path / "uploads")
    return svc.app.test_client()


def _subir(client, nombre="escrito.pdf", contenido=b"%PDF-1.4", tipo="PRUEBA"):
    return client.post(
        "/causa/1/documentos",
        headers=H,
        data={"file": (io.BytesIO(contenido), nombre), "tipo": tipo},
        content_type="multipart/form-data",
    )


def test_subir_documento_guarda_archivo_y_registro(client, db, tmp_path):
    resp = _subir(client)
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["nombre_archivo"] == "escrito.pdf"
    assert data["subido_por"] == 7
    assert data["tipo"] == "PRUEBA"
    archivos = list((tmp_path / "uploads").glob("*_escrito.pdf"))
    assert len(archivos) == 1
    assert archivos[0].read_bytes() == b"%PDF-1.4"
    assert db.query(Documento).count() == 1


def test_subir_sanea_el_nombre_del_archivo(client, tmp_path):
    resp = _subir(client, nombre="../../etc/passwd")
    assert resp.status_code == 201
    assert resp.get_json()["nombre_archivo"] == "etc_passwd"
    archivos = os.listdir(tmp_path / "uploads")
    assert len(archivos) == 1
    assert archivos[0].endswith("_etc_passwd")


def test_subir_sin_archivo_devuelve_400(client):
    resp = client.post("/causa/1/documentos", headers=H, data={}, content_type="multipart/form-data")
    assert resp.status_code == 400


def test_subir_con_nombre_vacio_devuelve_400(client):
    assert _subir(client, nombre="").status_code == 400


def test_listar_descargar_y_eliminar(client, tmp_path):
    doc_id = _subir(client, contenido=b"contenido").get_json()["id_documento"]

    lista = client.get("/causa/1/documentos", headers=H).get_json()
    assert [d["id_documento"] for d in lista] == [doc_id]
    assert client.get("/causa/2/documentos", headers=H).get_json() == []

    descarga = client.get(f"/{doc_id}", headers=H)
    assert descarga.status_code == 200
    assert descarga.data == b"contenido"
    assert "attachment" in descarga.headers["Content-Disposition"]
    assert "escrito.pdf" in descarga.headers["Content-Disposition"]
    descarga.close()

    assert client.delete(f"/{doc_id}", headers=H).status_code == 200
    assert len(os.listdir(tmp_path / "uploads")) == 0
    assert client.get(f"/{doc_id}", headers=H).status_code == 404


def test_eliminar_tolera_archivo_ya_borrado(client, db, tmp_path):
    doc_id = _subir(client).get_json()["id_documento"]
    doc = db.get(Documento, doc_id)
    os.remove(doc.ruta_storage)
    assert client.delete(f"/{doc_id}", headers=H).status_code == 200
    assert db.query(Documento).count() == 0


def test_eliminar_inexistente_devuelve_404(client):
    assert client.delete("/999", headers=H).status_code == 404


def test_dos_subidas_mismo_nombre_no_se_pisan_y_se_descargan_ambas(client, tmp_path):
    resp1 = _subir(client, nombre="documento.pdf", contenido=b"primer_contenido")
    assert resp1.status_code == 201
    id1 = resp1.get_json()["id_documento"]

    resp2 = _subir(client, nombre="documento.pdf", contenido=b"segundo_contenido")
    assert resp2.status_code == 201
    id2 = resp2.get_json()["id_documento"]

    assert id1 != id2
    archivos = os.listdir(tmp_path / "uploads")
    assert len(archivos) == 2

    descarga1 = client.get(f"/{id1}", headers=H)
    assert descarga1.status_code == 200
    assert descarga1.data == b"primer_contenido"
    descarga1.close()

    descarga2 = client.get(f"/{id2}", headers=H)
    assert descarga2.status_code == 200
    assert descarga2.data == b"segundo_contenido"
    descarga2.close()
