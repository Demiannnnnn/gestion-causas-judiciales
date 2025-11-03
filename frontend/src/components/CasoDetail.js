import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import apiFetch from '../utils/api';

function CasoDetail() {
  const [caso, setCaso] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({ rit: '', descripcion: '', estado: '' });
  const { id } = useParams();
  const navigate = useNavigate();

  useEffect(() => {
    apiFetch(`/api/casos/${id}`)
      .then(data => {
        setCaso(data);
        setFormData({ rit: data.rit, descripcion: data.descripcion, estado: data.estado });
      })
      .catch(error => console.error('Error al obtener detalles del caso:', error));
  }, [id]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prevState => ({ ...prevState, [name]: value }));
  };

  const handleUpdateCaso = (e) => {
    e.preventDefault();
    apiFetch(`/api/casos/${id}`,
     {
      method: 'PUT',
      body: JSON.stringify(formData),
    })
      .then(updatedCaso => {
        setCaso(updatedCaso);
        setIsEditing(false);
      })
      .catch(error => console.error('Error al actualizar caso:', error));
  };

  if (!caso) {
    return <div>Cargando...</div>;
  }

  return (
    <div className="card">
      <div className="card-header d-flex justify-content-between align-items-center">
        Detalles del Caso
        <button className="btn btn-secondary btn-sm" onClick={() => setIsEditing(!isEditing)}>
          {isEditing ? 'Cancelar' : 'Editar'}
        </button>
      </div>
      <div className="card-body">
        {isEditing ? (
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
                <option value="ARCHIVADA">Archivada</option>
              </select>
            </div>
            <button type="submit" className="btn btn-primary">Guardar Cambios</button>
          </form>
        ) : (
          <div>
            <h5 className="card-title">RIT: {caso.rit}</h5>
            <p className="card-text"><strong>ID Causa:</strong> {caso.id_causa}</p>
            <p className="card-text"><strong>Descripción:</strong> {caso.descripcion}</p>
            <p className="card-text"><strong>Estado:</strong> <span className={`badge bg-${caso.estado === 'ACTIVA' ? 'success' : 'secondary'}`}>{caso.estado}</span></p>
            <p className="card-text"><strong>Fecha de Inicio:</strong> {new Date(caso.fecha_inicio).toLocaleString()}</p>
            <button className="btn btn-primary" onClick={() => navigate('/casos')}>Volver</button>
          </div>
        )}
      </div>
    </div>
  );
}

export default CasoDetail;
