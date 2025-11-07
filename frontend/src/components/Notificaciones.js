import React, { useState, useEffect, useCallback } from 'react';

const API_URL = '/api';

function Notificaciones() {
  const [notificaciones, setNotificaciones] = useState([]);
  const [filtroTipo, setFiltroTipo] = useState('');
  const [filtroLeido, setFiltroLeido] = useState('');
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchNotificaciones = useCallback(() => {
    setLoading(true);
    let url = `${API_URL}/notificaciones?`;
    
    if (filtroTipo) url += `tipo=${filtroTipo}&`;
    if (filtroLeido) url += `leido=${filtroLeido}&`;

    fetch(url)
      .then(response => response.json())
      .then(data => {
        setNotificaciones(data);
        setLoading(false);
      })
      .catch(error => {
        console.error('Error al obtener notificaciones:', error);
        setLoading(false);
      });
  }, [filtroTipo, filtroLeido]);

  const fetchStats = useCallback(() => {
    fetch(`${API_URL}/notificaciones/stats`)
      .then(response => response.json())
      .then(data => setStats(data))
      .catch(error => console.error('Error al obtener estadísticas:', error));
  }, []);

  // Cargar notificaciones al montar el componente
  useEffect(() => {
    fetchNotificaciones();
    fetchStats();
  }, [fetchNotificaciones, fetchStats]);


  const marcarComoLeido = (id) => {
    fetch(`${API_URL}/notificaciones/${id}/marcar-leido`, {
      method: 'PUT',
    })
      .then(response => response.json())
      .then(() => {
        fetchNotificaciones();
        fetchStats();
      })
      .catch(error => console.error('Error al marcar como leído:', error));
  };

  const eliminarNotificacion = (id) => {
    if (window.confirm('¿Está seguro de eliminar esta notificación?')) {
      fetch(`${API_URL}/notificaciones/${id}`, {
        method: 'DELETE',
      })
        .then(() => {
          fetchNotificaciones();
          fetchStats();
        })
        .catch(error => console.error('Error al eliminar notificación:', error));
    }
  };

  const getTipoBadge = (tipo) => {
    const badges = {
      vencimiento: 'badge bg-warning text-dark',
      movimiento: 'badge bg-info',
      alerta: 'badge bg-danger',
      consolidado: 'badge bg-primary'
    };
    return badges[tipo] || 'badge bg-secondary';
  };

  const getTipoIcon = (tipo) => {
    const icons = {
      vencimiento: '⚠️',
      movimiento: '📋',
      alerta: '🚨',
      consolidado: '📊'
    };
    return icons[tipo] || '📧';
  };

  const formatFecha = (isoString) => {
    const fecha = new Date(isoString);
    return fecha.toLocaleString('es-CL', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div>
      <h2>Notificaciones y Alertas</h2>

      {/* Estadísticas */}
      {stats && (
        <div className="row mb-4">
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title">{stats.total}</h5>
                <p className="card-text text-muted">Total</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title text-danger">{stats.no_leidas}</h5>
                <p className="card-text text-muted">No Leídas</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title text-success">{stats.enviadas}</h5>
                <p className="card-text text-muted">Enviadas</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center">
              <div className="card-body">
                <h5 className="card-title text-warning">{stats.errores}</h5>
                <p className="card-text text-muted">Errores</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filtros */}
      <div className="card mb-4">
        <div className="card-header">Filtros</div>
        <div className="card-body">
          <div className="row">
            <div className="col-md-6">
              <label className="form-label">Tipo de Notificación</label>
              <select 
                className="form-select" 
                value={filtroTipo}
                onChange={(e) => setFiltroTipo(e.target.value)}
              >
                <option value="">Todas</option>
                <option value="vencimiento">Vencimientos</option>
                <option value="movimiento">Movimientos</option>
                <option value="alerta">Alertas</option>
                <option value="consolidado">Consolidados</option>
              </select>
            </div>
            <div className="col-md-6">
              <label className="form-label">Estado de Lectura</label>
              <select 
                className="form-select"
                value={filtroLeido}
                onChange={(e) => setFiltroLeido(e.target.value)}
              >
                <option value="">Todas</option>
                <option value="false">No Leídas</option>
                <option value="true">Leídas</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Lista de Notificaciones */}
      <div className="card">
        <div className="card-header">
          Listado de Notificaciones ({notificaciones.length})
        </div>
        <div className="card-body">
          {loading ? (
            <div className="text-center">
              <div className="spinner-border" role="status">
                <span className="visually-hidden">Cargando...</span>
              </div>
            </div>
          ) : notificaciones.length === 0 ? (
            <p className="text-muted text-center">No hay notificaciones</p>
          ) : (
            <div className="list-group">
              {notificaciones.map(notif => (
                <div 
                  key={notif.id} 
                  className={`list-group-item ${!notif.leido ? 'list-group-item-action border-start border-primary border-3' : ''}`}
                >
                  <div className="d-flex w-100 justify-content-between align-items-start">
                    <div className="flex-grow-1">
                      <div className="mb-2">
                        <span className="me-2">{getTipoIcon(notif.tipo)}</span>
                        <span className={getTipoBadge(notif.tipo)}>
                          {notif.tipo.toUpperCase()}
                        </span>
                        {!notif.leido && (
                          <span className="badge bg-danger ms-2">NUEVO</span>
                        )}
                        {notif.caso_rit !== 'N/A' && notif.caso_rit !== 'MÚLTIPLES' && (
                          <span className="badge bg-secondary ms-2">{notif.caso_rit}</span>
                        )}
                      </div>
                      <h6 className="mb-1">{notif.asunto}</h6>
                      <p className="mb-1 text-muted" style={{whiteSpace: 'pre-line'}}>
                        {notif.mensaje.length > 200 
                          ? notif.mensaje.substring(0, 200) + '...' 
                          : notif.mensaje}
                      </p>
                      <small className="text-muted">
                        📧 {notif.destinatario} • 🕐 {formatFecha(notif.fecha_envio)}
                      </small>
                    </div>
                    <div className="d-flex flex-column gap-2 ms-3">
                      {!notif.leido && (
                        <button 
                          className="btn btn-sm btn-primary"
                          onClick={() => marcarComoLeido(notif.id)}
                          title="Marcar como leído"
                        >
                          ✓
                        </button>
                      )}
                      <button 
                        className="btn btn-sm btn-danger"
                        onClick={() => eliminarNotificacion(notif.id)}
                        title="Eliminar"
                      >
                        🗑️
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Información adicional */}
      <div className="alert alert-info mt-4" role="alert">
        <h6 className="alert-heading">ℹ️ Sobre las Notificaciones</h6>
        <p className="mb-0">
          Las notificaciones se envían automáticamente por email cuando:
        </p>
        <ul className="mb-0">
          <li>Se acerca el vencimiento de un plazo (3 días antes)</li>
          <li>Hay un nuevo movimiento en un caso</li>
          <li>Se genera el consolidado diario (todos los días a las 8:00 AM)</li>
        </ul>
      </div>
    </div>
  );
}

export default Notificaciones;