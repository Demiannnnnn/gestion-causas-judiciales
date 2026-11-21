"""Tests de la lógica de ia-seguridad (alertas, análisis de logs y salud) con Docker simulado."""
import datetime
from unittest import mock

import docker
import pytest

from conftest import load_service

alert_manager = load_service("ia-seguridad", "alert_manager")
log_analyzer = load_service("ia-seguridad", "log_analyzer")
health_monitor = load_service("ia-seguridad", "health_monitor")


# --- AlertManager -----------------------------------------------------------

@pytest.fixture
def am():
    return alert_manager.AlertManager()


def test_crear_alertas_asigna_ids_correlativos(am):
    a = am.create_alert("low", "t1", "d", "c1")
    b = am.create_alert("critical", "t2", "d", "c2", metadata={"k": 1})
    assert (a["id"], b["id"]) == (1, 2)
    assert a["status"] == "open" and a["metadata"] == {}
    assert b["metadata"] == {"k": 1}


def test_filtrar_y_limitar_alertas(am):
    for sev in ("low", "high", "high", "critical"):
        am.create_alert(sev, "t", "d", "c")
    assert len(am.get_alerts(severity="high")) == 2
    assert len(am.get_alerts(limit=3)) == 3
    am.resolve_alert(1)
    assert [a["id"] for a in am.get_alerts(status="resolved")] == [1]


def test_resolver_alerta(am):
    am.create_alert("medium", "t", "d", "c")
    assert am.resolve_alert(1, "reiniciado") is True
    alerta = am.get_alert_by_id(1)
    assert alerta["status"] == "resolved"
    assert alerta["resolution_note"] == "reiniciado"
    assert alerta["resolved_at"] is not None
    assert am.resolve_alert(99) is False
    assert am.get_alert_by_id(99) is None


def test_estadisticas_cuentan_solo_abiertas_por_severidad(am):
    am.create_alert("critical", "t", "d", "c")
    am.create_alert("critical", "t", "d", "c")
    am.create_alert("low", "t", "d", "c")
    am.resolve_alert(1)
    stats = am.get_stats()
    assert stats["total"] == 3 and stats["open"] == 2 and stats["resolved"] == 1
    assert stats["by_severity"] == {"low": 1, "medium": 0, "high": 0, "critical": 1}


def test_limpieza_elimina_solo_resueltas_antiguas(am):
    am.create_alert("low", "abierta", "d", "c")
    am.create_alert("low", "reciente", "d", "c")
    am.create_alert("low", "antigua", "d", "c")
    am.resolve_alert(2)
    am.resolve_alert(3)
    am.alerts[2]["resolved_at"] = (datetime.datetime.now() - datetime.timedelta(days=40)).isoformat()
    assert am.cleanup_old_alerts(days=30) == 1
    assert [a["title"] for a in am.alerts] == ["abierta", "reciente"]


# --- LogAnalyzer --------------------------------------------------------------

@pytest.fixture
def docker_client():
    client = mock.MagicMock()
    with mock.patch.object(docker, "from_env", return_value=client):
        yield client


@pytest.fixture
def la(docker_client, monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    analyzer = log_analyzer.LogAnalyzer()
    analyzer.min_request_interval = 0
    return analyzer


@pytest.mark.parametrize("texto,segundos", [("2h", 7200), ("30m", 1800), ("45s", 45), ("x", 3600)])
def test_parse_time_string(la, texto, segundos):
    assert la._parse_time_string(texto) == segundos


def test_analisis_basico_cuenta_errores_y_criticos(la):
    logs = "\n".join([
        "INFO arrancando",
        "ERROR no se pudo conectar",
        "WARNING disco al 85%",
        "FATAL proceso terminado",
        "Exception en hilo",
    ])
    res = la._basic_log_analysis(logs, "db-master")
    assert res["mode"] == "basic"
    assert "Errores encontrados: 2" in res["analysis"]
    assert "Warnings encontrados: 1" in res["analysis"]
    assert "Mensajes críticos: 1" in res["analysis"]
    assert res["critical_issues"] == [{
        "title": "Problema crítico en db-master",
        "description": "FATAL proceso terminado",
        "container": "db-master",
        "severity": "critical",
    }]


def test_analisis_basico_sin_problemas(la):
    res = la._basic_log_analysis("todo bien\nok", "gateway")
    assert "No se detectaron problemas" in res["analysis"]
    assert res["critical_issues"] == []


def test_sin_api_key_gemini_usa_analisis_basico(la):
    assert la.gemini_model is None
    assert la.analyze_with_gemini("ERROR x", "redis")["mode"] == "basic"


def test_extraer_issues_criticos_maximo_5(la):
    texto = "\n".join(["Servicio caído"] * 7 + ["todo normal"])
    issues = la._extract_critical_issues(texto, "redis")
    assert len(issues) == 5
    assert all(i["severity"] == "critical" for i in issues)


def test_patrones_de_error(la):
    logs = "Connection refused\nconnection timeout\nPermission denied\nSQL error near\nOOM killer"
    patrones = la.get_error_patterns(logs)
    assert patrones["connection_errors"] == 2
    assert patrones["permission_errors"] == 1
    assert patrones["database_errors"] == 1
    assert patrones["memory_errors"] == 1
    assert "crash_errors" not in patrones


def test_get_container_logs_maneja_contenedor_inexistente(la, docker_client):
    docker_client.containers.get.side_effect = docker.errors.NotFound("no")
    assert la.get_container_logs("fantasma") is None


def test_analyze_containers_prioriza_y_limita_lote(la, docker_client):
    nombres = ["db-master", "db-slave", "proxysql", "redis", "redis-replica", "gateway", "frontend"]
    docker_client.containers.list.return_value = [mock.Mock(name=n) for n in nombres]
    for c, n in zip(docker_client.containers.list.return_value, nombres):
        c.name = n
    docker_client.containers.get.return_value.logs.return_value = b"ERROR algo\nFATAL otro"

    res = la.analyze_containers()
    analizados = [c["name"] for c in res["containers_analyzed"]]
    # Solo prioritarios (frontend no) y como máximo max_containers_per_batch.
    assert analizados == ["db-master", "db-slave", "proxysql", "redis", "redis-replica"]
    assert res["summary"]["critical_issues_found"] == 5
    assert all(c["mode"] == "basic" for c in res["containers_analyzed"])


def test_analyze_containers_marca_rate_limited_al_truncar(la, docker_client):
    docker_client.containers.get.return_value.logs.return_value = b"ok"
    res = la.analyze_containers(container_names=[f"c{i}" for i in range(8)])
    assert len(res["containers_analyzed"]) == 5
    assert res["rate_limited"] is True
    assert la.analyze_containers(container_names=["c1"])["rate_limited"] is False


def test_analyze_containers_registra_warning_sin_logs(la, docker_client):
    docker_client.containers.get.side_effect = docker.errors.NotFound("no")
    res = la.analyze_containers(container_names=["fantasma"])
    assert res["warnings"] == ["No se pudieron obtener logs de fantasma"]
    assert res["summary"]["analyzed"] == 0


# --- HealthMonitor -------------------------------------------------------------

def _contenedor(nombre, status="running", cpu=(200, 100, 2000, 1000), mem=(50, 100), restarts=0):
    c = mock.Mock()
    c.name = nombre
    c.status = status
    total, pre_total, sistema, pre_sistema = cpu
    c.stats.return_value = {
        "cpu_stats": {"cpu_usage": {"total_usage": total}, "system_cpu_usage": sistema},
        "precpu_stats": {"cpu_usage": {"total_usage": pre_total}, "system_cpu_usage": pre_sistema},
        "memory_stats": {"usage": mem[0] * 1024 * 1024, "limit": mem[1] * 1024 * 1024},
    }
    c.attrs = {"RestartCount": restarts, "Created": "2024-01-01", "State": {"Health": {"Status": "healthy"}}}
    return c


@pytest.fixture
def hm(docker_client):
    return health_monitor.HealthMonitor()


def test_check_container_health_calcula_cpu_y_memoria(hm, docker_client):
    docker_client.containers.get.return_value = _contenedor("api", mem=(50, 200))
    h = hm.check_container_health("api")
    assert h["cpu_percent"] == 10.0          # 100 / 1000
    assert h["memory_percent"] == 25.0
    assert h["memory_usage_mb"] == 50.0
    assert h["is_healthy"] is True


def test_check_container_health_no_encontrado(hm, docker_client):
    docker_client.containers.get.side_effect = docker.errors.NotFound("no")
    assert hm.check_container_health("x") == {"name": "x", "status": "not_found", "is_healthy": False}


def test_detect_anomalies(hm, docker_client):
    caido = _contenedor("db-slave", status="exited")
    cpu_alta = _contenedor("api", cpu=(1960, 1000, 2000, 1000))   # 96 %
    mem_alta = _contenedor("redis", mem=(90, 100), restarts=7)
    init = _contenedor("config-init-1", status="exited")
    por_nombre = {c.name: c for c in (caido, cpu_alta, mem_alta, init)}

    def listar(all=False):
        return list(por_nombre.values()) if all else [cpu_alta, mem_alta]

    docker_client.containers.list.side_effect = listar
    docker_client.containers.get.side_effect = lambda n: por_nombre[n]

    anomalias = {(a["type"], a["container"]): a for a in hm.detect_anomalies()}
    assert set(anomalias) == {
        ("container_down", "db-slave"),
        ("high_cpu_usage", "api"),
        ("high_memory_usage", "redis"),
        ("frequent_restarts", "redis"),
    }
    assert anomalias[("high_cpu_usage", "api")]["severity"] == "critical"
    assert anomalias[("high_memory_usage", "redis")]["severity"] == "high"
    assert "config-init-1" not in hm.expected_containers


def test_comparar_con_baseline(hm, docker_client):
    assert "error" in hm.compare_with_baseline("api")
    docker_client.containers.get.return_value = _contenedor("api", mem=(10, 100))
    hm.store_baseline_metrics("api")
    docker_client.containers.get.return_value = _contenedor("api", mem=(60, 100))
    cmp = hm.compare_with_baseline("api")
    assert cmp["memory_diff_percent"] == 50.0
    assert cmp["significant_change"] is True
