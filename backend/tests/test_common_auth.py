"""Tests del decorador ``token_required`` compartido por los servicios."""
import datetime

import pytest
from flask import Flask, jsonify

from common.auth import token_required
from conftest import make_token


@pytest.fixture
def client():
    app = Flask(__name__)

    @app.route("/protegido")
    @token_required
    def protegido(current_user):
        return jsonify(current_user)

    return app.test_client()


def test_sin_cabecera_devuelve_401(client):
    resp = client.get("/protegido")
    assert resp.status_code == 401
    assert "Falta el token" in resp.get_json()["message"]


def test_cabecera_sin_bearer_devuelve_401(client):
    resp = client.get("/protegido", headers={"Authorization": "tokensolo"})
    assert resp.status_code == 401
    assert "mal formado" in resp.get_json()["message"]


def test_token_valido_pasa_el_usuario_a_la_vista(client):
    token = make_token(rol="ASISTENTE", id_usuario=42)
    resp = client.get("/protegido", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["id_usuario"] == 42
    assert data["rol"] == "ASISTENTE"


def test_token_expirado_devuelve_401(client):
    token = make_token(expires_in=datetime.timedelta(seconds=-10))
    resp = client.get("/protegido", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401
    assert "expirado" in resp.get_json()["message"]


def test_token_firmado_con_otra_clave_devuelve_401(client):
    token = make_token(secret="otra-clave")
    resp = client.get("/protegido", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401
    assert "inválido" in resp.get_json()["message"]


def test_usa_secret_key_como_respaldo(client, monkeypatch):
    monkeypatch.delenv("JWT_SECRET_KEY")
    monkeypatch.setenv("SECRET_KEY", "respaldo")
    token = make_token(secret="respaldo")
    resp = client.get("/protegido", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200


def test_sin_clave_configurada_devuelve_500(client, monkeypatch):
    monkeypatch.delenv("JWT_SECRET_KEY")
    monkeypatch.delenv("SECRET_KEY", raising=False)
    resp = client.get("/protegido", headers={"Authorization": f"Bearer {make_token()}"})
    assert resp.status_code == 500
