"""Tests del servicio de autenticación (hash de contraseñas, JWT y /login)."""
import datetime

import jwt
import pytest

from common.models import Usuario
from conftest import load_service

auth = load_service("autenticacion", "auth")
svc = load_service("autenticacion")


def test_hash_y_verificacion_de_password():
    hashed = auth.get_password_hash("secreta")
    assert hashed != "secreta"
    assert auth.verify_password("secreta", hashed)
    assert not auth.verify_password("otra", hashed)


def test_create_access_token_incluye_datos_y_expiracion():
    token = auth.create_access_token({"id_usuario": 5, "rol": "ABOGADO"},
                                     expires_delta=datetime.timedelta(minutes=5))
    payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
    assert payload["id_usuario"] == 5
    assert payload["rol"] == "ABOGADO"
    restante = payload["exp"] - datetime.datetime.now(datetime.timezone.utc).timestamp()
    assert 0 < restante <= 300


def test_create_access_token_no_modifica_el_dict_original():
    data = {"id_usuario": 1}
    auth.create_access_token(data)
    assert data == {"id_usuario": 1}


@pytest.fixture
def client(db):
    db.add_all([
        Usuario(id_usuario=1, nombre="Ana", correo="ana@judicial.cl",
                password_hash=auth.get_password_hash("clave"), rol="ABOGADO", activo=True),
        Usuario(id_usuario=2, nombre="Beto", correo="beto@judicial.cl",
                password_hash=auth.get_password_hash("clave"), rol="ASISTENTE", activo=False),
    ])
    db.commit()
    return svc.app.test_client()


def test_login_correcto_devuelve_token(client):
    resp = client.post("/login", json={"correo": "ana@judicial.cl", "password": "clave"})
    assert resp.status_code == 200
    payload = jwt.decode(resp.get_json()["access_token"], auth.SECRET_KEY, algorithms=["HS256"])
    assert payload == {**payload, "id_usuario": 1, "rol": "ABOGADO"}


@pytest.mark.parametrize("body", [{}, {"correo": "ana@judicial.cl"}, {"password": "clave"}])
def test_login_sin_credenciales_devuelve_400(client, body):
    assert client.post("/login", json=body).status_code == 400


def test_login_password_incorrecta_devuelve_401(client):
    resp = client.post("/login", json={"correo": "ana@judicial.cl", "password": "mala"})
    assert resp.status_code == 401


def test_login_usuario_inexistente_devuelve_401(client):
    resp = client.post("/login", json={"correo": "nadie@judicial.cl", "password": "clave"})
    assert resp.status_code == 401


def test_login_usuario_inactivo_devuelve_403(client):
    resp = client.post("/login", json={"correo": "beto@judicial.cl", "password": "clave"})
    assert resp.status_code == 403


def test_health(client):
    assert client.get("/health").get_json() == {"status": "healthy"}
