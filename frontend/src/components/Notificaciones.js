import React, { useState, useEffect } from 'react';
import apiFetch from '../utils/api';

function Notificaciones() {
  const [notificaciones, setNotificaciones] = useState([]);

  useEffect(() => {
    fetchNotificaciones();
  }, []);

  const fetchNotificaciones = () => {
    apiFetch('/api/notificaciones')
      .then(data => setNotificaciones(data))
      .catch(error => console.error('Error al obtener notificaciones:', error));
  };

  const handleMarcarComoLeido = (id) => {
    apiFetch(`/api/notificaciones/${id}/leido`, { method: 'PUT' })
      .then(() => fetchNotificaciones())
      .catch(error => console.error('Error al marcar como leído:', error));
  };

  const handleDelete = (id) => {
    if (window.confirm('¿Está seguro de que desea eliminar esta notificación?')) {
      apiFetch(`/api/notificaciones/${id}`, { method: 'DELETE' })
        .then(() => fetchNotificaciones())
        .catch(error => console.error('Error al eliminar notificación:', error));
    }
  };

  return (
    <div>
      <h2>Notificaciones</h2>
      <div className="list-group">
        {notificaciones.map(notificacion => (
          <div key={notificacion.id_notificacion} className={`list-group-item list-group-item-action ${notificacion.leido ? 'list-group-item-light' : ''}`}>
            <div className="d-flex w-100 justify-content-between">
              <p className="mb-1">{notificacion.mensaje}</p>
              <small>{new Date(notificacion.fecha_creacion).toLocaleString()}</small>
            </div>
            <div className="mt-2">
              {!notificacion.leido && (
                <button className="btn btn-sm btn-primary me-2" onClick={() => handleMarcarComoLeido(notificacion.id_notificacion)}>Marcar como leído</button>
              )}
              <button className="btn btn-sm btn-danger" onClick={() => handleDelete(notificacion.id_notificacion)}>Eliminar</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default Notificaciones;
