from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
from datetime import datetime
import threading
import time

from log_analyzer import LogAnalyzer
from alert_manager import AlertManager
from health_monitor import HealthMonitor

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Inicializar componentes
log_analyzer = LogAnalyzer()
alert_manager = AlertManager()
health_monitor = HealthMonitor()

# Variable para controlar el análisis automático
analysis_running = False


# ==================== ENDPOINTS DE SALUD ====================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check para Docker"""
    return jsonify({
        "status": "healthy",
        "service": "ia-seguridad",
        "timestamp": datetime.now().isoformat(),
        "analysis_running": analysis_running
    }), 200


# ==================== ANÁLISIS DE LOGS ====================

@app.route('/analyze/logs', methods=['POST'])
def analyze_logs():
    """
    Analiza logs de contenedores específicos o todos
    
    Body JSON:
    {
        "containers": ["frontend", "backend-casos"],  // Opcional
        "since": "1h",  // Opcional: 1h, 30m, 24h
        "ai_provider": "gemini"  // Opcional: gemini, openai
    }
    """
    try:
        data = request.get_json() or {}
        containers = data.get('containers', [])
        since = data.get('since', '1h')
        ai_provider = data.get('ai_provider', 'gemini')
        
        logger.info(f"Iniciando análisis de logs - Contenedores: {containers or 'todos'}")
        
        # Analizar logs
        analysis_result = log_analyzer.analyze_containers(
            container_names=containers,
            since=since,
            ai_provider=ai_provider
        )
        
        # Generar alertas si hay problemas críticos
        if analysis_result.get('critical_issues'):
            for issue in analysis_result['critical_issues']:
                alert_manager.create_alert(
                    severity='critical',
                    title=issue['title'],
                    description=issue['description'],
                    container=issue['container']
                )
        
        return jsonify({
            "success": True,
            "analysis": analysis_result,
            "timestamp": datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Error en análisis de logs: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/analyze/container/<container_name>', methods=['GET'])
def analyze_specific_container(container_name):
    """Analiza un contenedor específico"""
    try:
        since = request.args.get('since', '1h')
        ai_provider = request.args.get('ai_provider', 'gemini')
        
        logger.info(f"Analizando contenedor: {container_name}")
        
        analysis = log_analyzer.analyze_containers(
            container_names=[container_name],
            since=since,
            ai_provider=ai_provider
        )
        
        return jsonify({
            "success": True,
            "container": container_name,
            "analysis": analysis
        }), 200
        
    except Exception as e:
        logger.error(f"Error analizando {container_name}: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==================== DETECCIÓN DE ANOMALÍAS ====================

@app.route('/anomalies/detect', methods=['POST'])
def detect_anomalies():
    """
    Detecta anomalías en el comportamiento de los contenedores
    """
    try:
        data = request.get_json() or {}
        containers = data.get('containers', [])
        
        logger.info("Iniciando detección de anomalías")
        
        anomalies = health_monitor.detect_anomalies(containers)
        
        # Crear alertas para anomalías detectadas
        for anomaly in anomalies:
            if anomaly['severity'] in ['high', 'critical']:
                alert_manager.create_alert(
                    severity=anomaly['severity'],
                    title=f"Anomalía detectada: {anomaly['type']}",
                    description=anomaly['description'],
                    container=anomaly['container']
                )
        
        return jsonify({
            "success": True,
            "anomalies": anomalies,
            "total": len(anomalies)
        }), 200
        
    except Exception as e:
        logger.error(f"Error detectando anomalías: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==================== ALERTAS ====================

@app.route('/alerts', methods=['GET'])
def get_alerts():
    """Obtiene todas las alertas"""
    try:
        severity = request.args.get('severity')
        status = request.args.get('status')
        limit = int(request.args.get('limit', 50))
        
        alerts = alert_manager.get_alerts(
            severity=severity,
            status=status,
            limit=limit
        )
        
        return jsonify({
            "success": True,
            "alerts": alerts,
            "total": len(alerts)
        }), 200
        
    except Exception as e:
        logger.error(f"Error obteniendo alertas: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/alerts/<int:alert_id>/resolve', methods=['PUT'])
def resolve_alert(alert_id):
    """Marca una alerta como resuelta"""
    try:
        data = request.get_json() or {}
        resolution_note = data.get('note', '')
        
        alert_manager.resolve_alert(alert_id, resolution_note)
        
        return jsonify({
            "success": True,
            "message": "Alerta resuelta"
        }), 200
        
    except Exception as e:
        logger.error(f"Error resolviendo alerta: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==================== ESTADÍSTICAS ====================

@app.route('/stats/system', methods=['GET'])
def get_system_stats():
    """Obtiene estadísticas del sistema"""
    try:
        stats = health_monitor.get_system_stats()
        
        return jsonify({
            "success": True,
            "stats": stats
        }), 200
        
    except Exception as e:
        logger.error(f"Error obteniendo estadísticas: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/stats/containers', methods=['GET'])
def get_containers_health():
    """Obtiene el estado de salud de todos los contenedores"""
    try:
        health_data = health_monitor.check_all_containers()
        
        return jsonify({
            "success": True,
            "containers": health_data,
            "timestamp": datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Error obteniendo salud de contenedores: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


# ==================== ANÁLISIS AUTOMÁTICO ====================

def run_automatic_analysis():
    """Ejecuta análisis automático cada cierto tiempo"""
    global analysis_running
    analysis_running = True
    
    logger.info("Iniciando análisis automático de logs")
    
    while analysis_running:
        try:
            # Analizar logs cada 5 minutos
            logger.info("Ejecutando análisis automático...")
            
            # Analizar todos los contenedores
            analysis = log_analyzer.analyze_containers(
                container_names=[],
                since='5m',
                ai_provider='gemini'
            )
            
            # Detectar anomalías
            anomalies = health_monitor.detect_anomalies([])
            
            logger.info(f"Análisis completado - Issues encontrados: {len(analysis.get('issues', []))}")
            logger.info(f"Anomalías detectadas: {len(anomalies)}")
            
            # Esperar 5 minutos
            time.sleep(300)
            
        except Exception as e:
            logger.error(f"Error en análisis automático: {str(e)}")
            time.sleep(60)


@app.route('/analysis/start', methods=['POST'])
def start_automatic_analysis():
    """Inicia el análisis automático"""
    global analysis_running
    
    if not analysis_running:
        thread = threading.Thread(target=run_automatic_analysis, daemon=True)
        thread.start()
        return jsonify({
            "success": True,
            "message": "Análisis automático iniciado"
        }), 200
    else:
        return jsonify({
            "success": False,
            "message": "Análisis automático ya está en ejecución"
        }), 400


@app.route('/analysis/stop', methods=['POST'])
def stop_automatic_analysis():
    """Detiene el análisis automático"""
    global analysis_running
    analysis_running = False
    
    return jsonify({
        "success": True,
        "message": "Análisis automático detenido"
    }), 200


# ==================== CONFIGURACIÓN ====================

@app.route('/config', methods=['GET'])
def get_config():
    """Obtiene la configuración actual"""
    return jsonify({
        "success": True,
        "config": {
            "ai_provider": os.getenv('AI_PROVIDER', 'gemini'),
            "analysis_interval": "5m",
            "log_retention": "7d",
            "alert_threshold": "medium"
        }
    }), 200


if __name__ == '__main__':
    # Iniciar análisis automático al arrancar
    analysis_thread = threading.Thread(target=run_automatic_analysis, daemon=True)
    analysis_thread.start()
    
    # Iniciar Flask
    app.run(host='0.0.0.0', port=8005, debug=False)
