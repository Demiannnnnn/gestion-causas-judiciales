import React, { useState, useEffect } from 'react';
import './IASeguridad.css';

const API_URL = '/api/ia-seguridad';

function IASeguridad() {
  const [alerts, setAlerts] = useState([]);
  const [systemStats, setSystemStats] = useState(null);
  const [containerHealth, setContainerHealth] = useState([]);
  const [analyzing, setAnalyzing] = useState(false);
  const [selectedContainer, setSelectedContainer] = useState('');
  const [analysisResult, setAnalysisResult] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
    // Actualizar cada 30 segundos
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    try {
      await Promise.all([
        fetchAlerts(),
        fetchSystemStats(),
        fetchContainerHealth()
      ]);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching data:', error);
      setLoading(false);
    }
  };

  const fetchAlerts = async () => {
    try {
      const response = await fetch(`${API_URL}/alerts?status=open`);
      const data = await response.json();
      if (data.success) {
        setAlerts(data.alerts);
      }
    } catch (error) {
      console.error('Error fetching alerts:', error);
    }
  };

  const fetchSystemStats = async () => {
    try {
      const response = await fetch(`${API_URL}/stats/system`);
      const data = await response.json();
      if (data.success) {
        setSystemStats(data.stats);
      }
    } catch (error) {
      console.error('Error fetching system stats:', error);
    }
  };

  const fetchContainerHealth = async () => {
    try {
      const response = await fetch(`${API_URL}/stats/containers`);
      const data = await response.json();
      if (data.success) {
        setContainerHealth(data.containers);
      }
    } catch (error) {
      console.error('Error fetching container health:', error);
    }
  };

  const analyzeAllLogs = async () => {
    setAnalyzing(true);
    try {
      const response = await fetch(`${API_URL}/analyze/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ since: '1h' })
      });
      const data = await response.json();
      if (data.success) {
        setAnalysisResult(data.analysis);
        alert('Análisis completado. Revise los resultados abajo.');
      }
    } catch (error) {
      console.error('Error analyzing logs:', error);
      alert('Error al analizar logs');
    } finally {
      setAnalyzing(false);
    }
  };

  const analyzeContainer = async () => {
    if (!selectedContainer) {
      alert('Seleccione un contenedor');
      return;
    }
    
    setAnalyzing(true);
    try {
      const response = await fetch(`${API_URL}/analyze/container/${selectedContainer}?since=1h`);
      const data = await response.json();
      if (data.success) {
        setAnalysisResult(data.analysis);
      }
    } catch (error) {
      console.error('Error analyzing container:', error);
      alert('Error al analizar contenedor');
    } finally {
      setAnalyzing(false);
    }
  };

  const detectAnomalies = async () => {
    try {
      const response = await fetch(`${API_URL}/anomalies/detect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
      const data = await response.json();
      if (data.success) {
        alert(`Detectadas ${data.total} anomalías`);
        fetchAlerts();
      }
    } catch (error) {
      console.error('Error detecting anomalies:', error);
    }
  };

  const resolveAlert = async (alertId) => {
    try {
      const response = await fetch(`${API_URL}/alerts/${alertId}/resolve`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ note: 'Resuelto desde dashboard' })
      });
      if (response.ok) {
        fetchAlerts();
      }
    } catch (error) {
      console.error('Error resolving alert:', error);
    }
  };

  const getSeverityBadge = (severity) => {
    const badges = {
      low: 'badge bg-info',
      medium: 'badge bg-warning',
      high: 'badge bg-danger',
      critical: 'badge bg-dark'
    };
    return badges[severity] || 'badge bg-secondary';
  };

  const getHealthBadge = (isHealthy) => {
    return isHealthy ? 'badge bg-success' : 'badge bg-danger';
  };

  if (loading) {
    return (
      <div className="text-center mt-5">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Cargando...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="ia-seguridad-container">
      <h2 className="mb-4">🤖 IA - Seguridad y Monitoreo</h2>

      {/* Estadísticas del Sistema */}
      {systemStats && (
        <div className="row mb-4">
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">CPU Host</h5>
                <p className="card-text display-6">{systemStats.host.cpu_percent}%</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Memoria Host</h5>
                <p className="card-text display-6">{systemStats.host.memory_percent}%</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Contenedores</h5>
                <p className="card-text display-6">{systemStats.docker.running}/{systemStats.docker.total_containers}</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">Alertas Abiertas</h5>
                <p className="card-text display-6 text-danger">{alerts.length}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Controles de Análisis */}
      <div className="card mb-4">
        <div className="card-header">Análisis de Logs con IA</div>
        <div className="card-body">
          <div className="row">
            <div className="col-md-6">
              <button 
                className="btn btn-primary w-100 mb-2" 
                onClick={analyzeAllLogs}
                disabled={analyzing}
              >
                {analyzing ? '🔄 Analizando...' : '🔍 Analizar Todos los Contenedores'}
              </button>
            </div>
            <div className="col-md-6">
              <button 
                className="btn btn-warning w-100 mb-2" 
                onClick={detectAnomalies}
              >
                ⚠️ Detectar Anomalías
              </button>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-md-8">
              <select 
                className="form-select" 
                value={selectedContainer}
                onChange={(e) => setSelectedContainer(e.target.value)}
              >
                <option value="">Seleccionar contenedor específico...</option>
                {containerHealth.map(c => (
                  <option key={c.name} value={c.name}>{c.name}</option>
                ))}
              </select>
            </div>
            <div className="col-md-4">
              <button 
                className="btn btn-secondary w-100" 
                onClick={analyzeContainer}
                disabled={!selectedContainer || analyzing}
              >
                Analizar Seleccionado
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Resultados del Análisis */}
      {analysisResult && (
        <div className="card mb-4">
          <div className="card-header bg-success text-white">
            Resultados del Análisis - {new Date().toLocaleString()}
          </div>
          <div className="card-body">
            {analysisResult.summary && (
              <div className="alert alert-info">
                <strong>Resumen:</strong> Analizados {analysisResult.summary.analyzed} de {analysisResult.summary.total_containers} contenedores.
                {analysisResult.summary.critical_issues_found > 0 && (
                  <span className="text-danger"> ⚠️ {analysisResult.summary.critical_issues_found} problemas críticos encontrados.</span>
                )}
              </div>
            )}
            
            {analysisResult.containers_analyzed && analysisResult.containers_analyzed.map((container, idx) => (
              <div key={idx} className="mb-3">
                <h5>📦 {container.name}</h5>
                <div className="analysis-content">
                  <pre className="bg-light p-3 rounded" style={{whiteSpace: 'pre-wrap'}}>
                    {container.analysis}
                  </pre>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Alertas Activas */}
      <div className="card mb-4">
        <div className="card-header">
          🚨 Alertas Activas ({alerts.length})
        </div>
        <div className="card-body">
          {alerts.length === 0 ? (
            <p className="text-muted text-center">No hay alertas activas</p>
          ) : (
            <div className="list-group">
              {alerts.map(alert => (
                <div key={alert.id} className="list-group-item">
                  <div className="d-flex w-100 justify-content-between">
                    <div>
                      <h6 className="mb-1">
                        <span className={getSeverityBadge(alert.severity)}>
                          {alert.severity.toUpperCase()}
                        </span>
                        {' '}{alert.title}
                      </h6>
                      <p className="mb-1">{alert.description}</p>
                      <small className="text-muted">
                        📦 {alert.container} | 🕐 {new Date(alert.created_at).toLocaleString()}
                      </small>
                    </div>
                    <div>
                      <button 
                        className="btn btn-sm btn-success" 
                        onClick={() => resolveAlert(alert.id)}
                      >
                        ✓ Resolver
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Estado de Contenedores */}
      <div className="card">
        <div className="card-header">Estado de Contenedores</div>
        <div className="card-body">
          <div className="table-responsive">
            <table className="table table-hover">
              <thead>
                <tr>
                  <th>Contenedor</th>
                  <th>Estado</th>
                  <th>Salud</th>
                  <th>CPU</th>
                  <th>Memoria</th>
                  <th>Reinicios</th>
                </tr>
              </thead>
              <tbody>
                {containerHealth.map((container, idx) => (
                  <tr key={idx}>
                    <td>{container.name}</td>
                    <td>
                      <span className={`badge ${container.status === 'running' ? 'bg-success' : 'bg-danger'}`}>
                        {container.status}
                      </span>
                    </td>
                    <td>
                      <span className={getHealthBadge(container.is_healthy)}>
                        {container.is_healthy ? 'Saludable' : 'Problemas'}
                      </span>
                    </td>
                    <td>{container.cpu_percent}%</td>
                    <td>{container.memory_percent}%</td>
                    <td>{container.restart_count || 0}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Información */}
      <div className="alert alert-info mt-4">
        <h6 className="alert-heading">ℹ️ Sobre el Sistema de IA</h6>
        <ul className="mb-0">
          <li><strong>Análisis Manual:</strong> Presione el botón "Analizar" para ejecutar el análisis con IA</li>
          <li>La IA analiza logs de contenedores y detecta errores, warnings y anomalías</li>
          <li>Genera alertas automáticas cuando se encuentran problemas críticos</li>
          <li><strong>Estadísticas actualizadas cada 30 segundos</strong> (CPU, memoria, estado) sin usar IA</li>
          <li>El análisis con IA se ejecuta <strong>solo cuando usted lo solicita</strong> para optimizar el uso de la API</li>
        </ul>
      </div>
    </div>
  );
}

export default IASeguridad;
