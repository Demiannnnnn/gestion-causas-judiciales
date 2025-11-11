import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import apiFetch from '../utils/api';

function CasoDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [caso, setCaso] = useState(null);
  const [partes, setPartes] = useState([]);
  const [movimientos, setMovimientos] = useState([]);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    rit: '',
    descripcion: '',
    estado: 'ACTIVA',
  });
  const [newMovimiento, setNewMovimiento] = useState({
    tipo: '',
    fecha: '',
    descripcion: '',
  });

  useEffect(() => {
    // Obtener detalles del caso
    apiFetch(`/api/casos/${id}`)
      .then(data => {
        setCaso(data);
        setFormData({
          rit: data.rit,
          descripcion: data.descripcion,
          estado: data.estado,
        });
      })
      .catch(error => console.error('Error al obtener detalles del caso:', error));

    // Obtener partes del caso
    apiFetch(`/api/casos/${id}/partes`)
      .then(data => setPartes(data))
      .catch(error => console.error('Error al obtener partes del caso:', error));

    // Obtener movimientos del caso
    fetchMovimientos();
  }, [id]);

  const fetchMovimientos = () => {
    apiFetch(`/api/casos/${id}/movimientos`)
      .then(data => setMovimientos(data))
      .catch(error => console.error('Error al obtener movimientos del caso:', error));
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleMovimientoInputChange = (e) => {
    const { name, value } = e.target;
    setNewMovimiento(prev => ({ ...prev, [name]: value }));
  };

  const handleUpdateCaso = (e) => {
    e.preventDefault();
    apiFetch(`/api/casos/${id}`, {
      method: 'PUT',
      body: JSON.stringify(formData),
    })
      .then(updatedCaso => {
        setCaso(updatedCaso);
        setIsEditing(false);
      })
      .catch(error => console.error('Error al actualizar el caso:', error));
  };

  const handleCreateMovimiento = async (e) => {
    e.preventDefault();
    try {
      await apiFetch(`/api/casos/${id}/movimientos`, {
        method: 'POST',
        body: JSON.stringify(newMovimiento),
      });
      fetchMovimientos(); // Recargar la lista de movimientos
      setNewMovimiento({ tipo: '', fecha: '', descripcion: '' }); // Limpiar formulario
    } catch (error) {
      console.error('Error al crear movimiento:', error);
      alert('Error al crear movimiento. Por favor, revise la consola para más detalles.');
    }
  };

  if (!caso) {
    return <div>Cargando...</div>;
  }

  return (
    <div>
      <h2>Detalle del Caso: {caso.rit}</h2>

      {isEditing ? (
        <div className="card mb-4">
          <div className="card-header">Editando Caso</div>
          <div className="card-body">
            <form onSubmit={handleUpdateCaso}>
              <div className="mb-3">
                <label htmlFor="rit" className="form-label">RIT</label>
                <input type="text" className="form-control" id="rit" name="rit" value={formData.rit} onChange={handleInputChange} required />
              </div>
              <div className="mb-3">
                <label htmlFor="descripcion" className="form-label">Descripción</label>
                <textarea className="form-control" id="descripcion" name="descripcion" rows="3" value={formData.descripcion} onChange={handleInputChange}></textarea>
              </div>
              <div className="mb-3">
                <label htmlFor="estado" className="form-label">Estado</label>
                <select className="form-select" id="estado" name="estado" value={formData.estado} onChange={handleInputChange}>
                  <option value="ACTIVA">Activa</option>
                  <option value="CONGELADA">Congelada</option>
                  <option value="ARCHIVADA">Archivada</option>
                </select>
              </div>
              <button type="submit" className="btn btn-primary">Guardar Cambios</button>
              <button type="button" className="btn btn-secondary ms-2" onClick={() => setIsEditing(false)}>Cancelar</button>
            </form>
          </div>
        </div>
      ) : (
        <div className="card mb-4">
          <div className="card-header">Información General</div>
          <div className="card-body">
            <p><strong>ID Causa:</strong> {caso.id_causa}</p>
            <p><strong>Estado:</strong> <span className={`badge bg-${caso.estado === 'ACTIVA' ? 'success' : 'secondary'}`}>{caso.estado}</span></p>
            <p><strong>Fecha de Inicio:</strong> {new Date(caso.fecha_inicio).toLocaleDateString()}</p>
            <p><strong>Descripción:</strong> {caso.descripcion}</p>
            <button className="btn btn-primary" onClick={() => setIsEditing(true)}>Editar</button>
            <button className="btn btn-secondary ms-2" onClick={() => navigate('/casos')}>Volver</button>
          </div>
        </div>
      )}

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

      <div className="card mt-4">
        <div className="card-header">Añadir Nuevo Movimiento</div>
        <div className="card-body">
          <form onSubmit={handleCreateMovimiento}>
            <div className="row mb-3">
              <div className="col-md-6">
                <label htmlFor="tipo" className="form-label">Tipo de Movimiento</label>
                <select className="form-select" id="tipo" name="tipo" value={newMovimiento.tipo} onChange={handleMovimientoInputChange} required>
                  <option value="" disabled>Seleccione un tipo...</option>
                  <option value="AUDIENCIA">Audiencia</option>
                  <option value="RESOLUCIÓN">Resolución</option>
                  <option value="SUSPENSIÓN">Suspensión</option>
                  <option value="VENCIMIENTO">Vencimiento</option>
                  <option value="OTRO">Otro</option>
                </select>
              </div>
              <div className="col-md-6">
                <label htmlFor="fecha" className="form-label">Fecha</label>
                <input type="date" className="form-control" id="fecha" name="fecha" value={newMovimiento.fecha} onChange={handleMovimientoInputChange} required />
              </div>
            </div>
            <div className="mb-3">
              <label htmlFor="descripcion" className="form-label">Descripción</label>
              <textarea className="form-control" id="descripcion" name="descripcion" rows="3" value={newMovimiento.descripcion} onChange={handleMovimientoInputChange} required></textarea>
            </div>
            <button type="submit" className="btn btn-primary">Añadir Movimiento</button>
          </form>
        </div>
      </div>
    </div>
  );
}

export default CasoDetail;
