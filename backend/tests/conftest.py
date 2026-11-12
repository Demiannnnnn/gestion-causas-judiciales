"""Configuración común de los tests unitarios del backend.

Los servicios importan ``common.database.db_manager`` al cargarse, y este exige
``DATABASE_URL``. Para no depender de MySQL, se define una URL ficticia antes de
importar nada y luego se sustituyen las sesiones por una base SQLite en memoria.
"""
import datetime
import importlib.util
import os
import sys
import types

import jwt
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_SECRET = "clave-de-test"

# URL de archivo (QueuePool) para que acepte pool_size/max_overflow; nunca se
# llega a conectar porque las sesiones se sustituyen en el fixture ``db``.
os.environ.setdefault("DATABASE_URL", "sqlite:///no-usada.db")
os.environ["JWT_SECRET_KEY"] = TEST_SECRET
for _rol in ("ABOGADO", "ASISTENTE", "ADMINISTRADOR", "SISTEMAS"):
    os.environ.pop(f"DATABASE_URL_{_rol}", None)

if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)


def _stub_module(name, **attrs):
    """Registra un módulo falso si la dependencia real no está instalada."""
    try:
        importlib.import_module(name)
    except ImportError:
        module = types.ModuleType(name)
        for key, value in attrs.items():
            setattr(module, key, value)
        sys.modules[name] = module


# Los SDK de IA solo se usan con API keys; en los tests basta con un sustituto.
_stub_module("google")
_stub_module("google.generativeai", configure=lambda **_: None, GenerativeModel=object)
if "google.generativeai" in sys.modules and not hasattr(sys.modules["google"], "generativeai"):
    sys.modules["google"].generativeai = sys.modules["google.generativeai"]
_stub_module("openai", OpenAI=object)

from common.database import db_manager  # noqa: E402
from common.models import Base  # noqa: E402

_loaded_services = {}


def load_service(service, module="app"):
    """Importa ``backend/<service>/app/<module>.py`` con un nombre único.

    Todos los servicios llaman ``app.py`` a su módulo principal, así que se
    cargan por ruta para que no choquen entre sí en ``sys.modules``.
    """
    key = (service, module)
    if key in _loaded_services:
        return _loaded_services[key]
    app_dir = os.path.join(BACKEND_DIR, service, "app")
    if app_dir not in sys.path:
        sys.path.insert(0, app_dir)
    name = f"svc_{service.replace('-', '_')}_{module}"
    spec = importlib.util.spec_from_file_location(name, os.path.join(app_dir, f"{module}.py"))
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    _loaded_services[key] = mod
    return mod


@pytest.fixture
def db_session_factory():
    """Base SQLite en memoria enchufada en ``db_manager`` durante el test."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    factory = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    saved = dict(db_manager.SessionLocals)
    db_manager.SessionLocals.clear()
    db_manager.SessionLocals["default"] = factory
    try:
        yield factory
    finally:
        db_manager.SessionLocals.clear()
        db_manager.SessionLocals.update(saved)
        Base.metadata.drop_all(engine)
        engine.dispose()


@pytest.fixture
def db(db_session_factory):
    """Sesión para preparar y comprobar datos directamente."""
    session = db_session_factory()
    try:
        yield session
    finally:
        session.close()


def make_token(rol="ABOGADO", id_usuario=1, expires_in=datetime.timedelta(hours=1), secret=TEST_SECRET):
    payload = {
        "id_usuario": id_usuario,
        "rol": rol,
        "exp": datetime.datetime.now(datetime.timezone.utc) + expires_in,
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def auth_header(rol="ABOGADO", id_usuario=1):
    return {"Authorization": f"Bearer {make_token(rol, id_usuario)}"}
