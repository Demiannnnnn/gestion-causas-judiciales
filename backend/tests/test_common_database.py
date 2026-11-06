"""Tests de ``DatabaseManager``: selección de conexión por rol y transacciones."""
from unittest import mock

import pytest

from common import database
from common.models import Tribunal


def _crear_manager(monkeypatch, **urls):
    monkeypatch.setenv("DATABASE_URL", "mysql://default")
    for rol in ("ABOGADO", "ASISTENTE", "ADMINISTRADOR", "SISTEMAS"):
        monkeypatch.delenv(f"DATABASE_URL_{rol}", raising=False)
    for rol, url in urls.items():
        monkeypatch.setenv(f"DATABASE_URL_{rol}", url)
    with mock.patch.object(database, "create_engine") as fake_engine:
        fake_engine.side_effect = lambda url, **kw: mock.Mock(name=url, url=url)
        manager = database.DatabaseManager()
    return manager, fake_engine


def test_sin_database_url_falla(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(ValueError):
        database.DatabaseManager()


def test_crea_motor_por_rol_configurado(monkeypatch):
    manager, fake_engine = _crear_manager(monkeypatch, ABOGADO="mysql://abogado", SISTEMAS="mysql://sistemas")
    assert set(manager.engines) == {"default", "ABOGADO", "SISTEMAS"}
    assert manager.engines["ABOGADO"].url == "mysql://abogado"
    # Todos los motores llevan las opciones de pool y timeouts.
    for call in fake_engine.call_args_list:
        assert call.kwargs["pool_pre_ping"] is True
        assert call.kwargs["connect_args"]["connect_timeout"] == 10


def _manager_con_sesiones():
    manager = database.DatabaseManager.__new__(database.DatabaseManager)
    default_session = mock.Mock(name="default")
    abogado_session = mock.Mock(name="abogado")
    manager.SessionLocals = {
        "default": mock.Mock(return_value=default_session),
        "ABOGADO": mock.Mock(return_value=abogado_session),
    }
    return manager, default_session, abogado_session


def test_get_session_usa_la_sesion_del_rol():
    manager, default_session, abogado_session = _manager_con_sesiones()
    with manager.get_session(role="ABOGADO") as s:
        assert s is abogado_session
    abogado_session.commit.assert_called_once()
    abogado_session.close.assert_called_once()
    default_session.commit.assert_not_called()


def test_get_session_rol_desconocido_usa_default():
    manager, default_session, _ = _manager_con_sesiones()
    with manager.get_session(role="INVITADO") as s:
        assert s is default_session


def test_get_session_hace_rollback_y_relanza_errores():
    manager, default_session, _ = _manager_con_sesiones()
    with pytest.raises(RuntimeError):
        with manager.get_session():
            raise RuntimeError("fallo")
    default_session.rollback.assert_called_once()
    default_session.commit.assert_not_called()
    default_session.close.assert_called_once()


def test_get_session_persiste_en_bd_real(db_session_factory):
    with database.db_manager.get_session() as s:
        s.add(Tribunal(nombre="1er Juzgado Civil"))
    with database.db_manager.get_session() as s:
        assert s.query(Tribunal).count() == 1
