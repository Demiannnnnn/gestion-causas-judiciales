import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import apiFetch from '../utils/api';

function CasoDetail() {
  const { id } = useParams();
  const [caso, setCaso] = useState(null);
  const [partes, setPartes] = useState([]);
  const [movimientos, setMovimientos] = useState([]);

  useEffect(() => {
    // Obtener detalles del caso
    apiFetch(`/api/casos/${id}`)
      .then(data => setCaso(data))
      .catch(error => console.error('Error al obtener detalles del caso:', error));

    // Obtener partes del caso
    apiFetch(`/api/casos/${id}/partes`)
      .then(data => setPartes(data))
      .catch(error => console.error('Error al obtener partes del caso:', error));

    // Obtener movimientos del caso
    apiFetch(`/api/casos/${id}/movimientos`)
      .then(data => setMovimientos(data))
      .catch(error => console.error('Error al obtener movimientos del caso:', error));
  }, [id]);

  if (!caso) {
    return <div>Cargando...</div>;
  }

  return (
    <div>
      <h2>Detalle del Caso: {caso.rit}</h2>
      <div className="card mb-4">
        <div className="card-header">Información General</div>
        <div className="card-body">
          <p><strong>ID Causa:</strong> {caso.id_causa}</p>
          <p><strong>Estado:</strong> <span className={`badge bg-${caso.estado === 'ACTIVA' ? 'success' : 'secondary'}`}>{caso.estado}</span></p>
          <p><strong>Fecha de Inicio:</strong> {new Date(caso.fecha_inicio).toLocaleDateString()}</p>
          <p><strong>Descripción:</strong> {caso.descripcion}</p>
        </div>
      </div>

      <div className="card mb-4">
        <div className="card-header">Partes Involucradas</div>
        <div className="card-body">
          <table className="table">
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Tipo</th>
                <th>Representante</th>
              </tr>
            </thead>
            <tbody>
              {partes.map((parte, index) => (
                <tr key={index}>
                  <td>{parte.nombre}</td>
                  <td>{parte.tipo}</td>
                  <td>{parte.representante}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="card">
        <div className="card-header">Línea de Tiempo (Movimientos)</div>
        <div className="card-body">
          <ul className="list-group">
            {movimientos.map((movimiento, index) => (
              <li key={index} className="list-group-item">
                <p><strong>Fecha:</strong> {new Date(movimiento.fecha).toLocaleString()}</p>
                <p><strong>Tipo:</strong> {movimiento.tipo}</p>
                <p><strong>Descripción:</strong> {movimiento.descripcion}</p>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

export default CasoDetail;