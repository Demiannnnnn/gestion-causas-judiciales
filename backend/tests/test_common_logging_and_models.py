"""Tests del formateador JSON de logs y de la serialización de modelos."""
import datetime
import io
import json
import logging

import pytest

from common.logging_utils import JsonFormatter, get_logger
from common.models import Causa, Documento, Notificacion


def test_json_formatter_incluye_campos_y_excepcion():
    logger = logging.getLogger("test.json")
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    logger.addHandler(handler)
    logger.propagate = False
    try:
        try:
            raise ValueError("boom")
        except ValueError:
            logger.exception("algo falló %s", "aquí")
    finally:
        logger.removeHandler(handler)

    record = json.loads(stream.getvalue())
    assert record["level"] == "ERROR"
    assert record["message"] == "algo falló aquí"
    assert record["logger_name"] == "test.json"
    assert record["timestamp"].endswith("Z")
    assert "ValueError: boom" in record["exception"]


def test_get_logger_devuelve_el_mismo_logger():
    assert get_logger("test.unico") is get_logger("test.unico")


def test_get_logger_anade_handler_json_aunque_root_tenga_handlers():
    logging.basicConfig()  # lo mismo que hace common/auth.py al importarse
    logger = get_logger("servicio.con.root")
    assert any(isinstance(h.formatter, JsonFormatter) for h in logger.handlers)


def test_get_logger_llamadas_repetidas_no_duplican_handlers():
    logger1 = get_logger("servicio.repetido")
    cantidad_handlers = len(logger1.handlers)
    logger2 = get_logger("servicio.repetido")
    assert logger1 is logger2
    assert len(logger2.handlers) == cantidad_handlers


def test_causa_to_json_formatea_fecha():
    causa = Causa(id_causa=1, rit="C-1-2024", tribunal_id=2,
                  fecha_inicio=datetime.date(2024, 3, 5), estado="ACTIVA", descripcion="x")
    assert causa.to_json() == {
        "id_causa": 1, "rit": "C-1-2024", "tribunal_id": 2,
        "fecha_inicio": "2024-03-05", "estado": "ACTIVA", "descripcion": "x",
    }
    assert Causa(rit="C-2").to_json()["fecha_inicio"] is None


def test_documento_to_json_no_expone_ruta_storage():
    doc = Documento(id_documento=3, id_causa=1, tipo="OFICIO", nombre_archivo="a.pdf",
                    ruta_storage="/app/uploads/a.pdf", subido_por=7)
    data = doc.to_json()
    assert "ruta_storage" not in data
    assert data["fecha_subida"] is None


def test_notificacion_to_json():
    n = Notificacion(id_notificacion=9, tipo="ALERTA", destinatario="a@b.cl", asunto="s",
                     mensaje="m", fecha_envio=datetime.datetime(2024, 1, 1, 12, 0), leido=False)
    data = n.to_json()
    assert data["id"] == 9
    assert data["fecha_envio"] == "2024-01-01T12:00:00"
