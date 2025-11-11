import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom'; // Importar Link
import apiFetch from '../utils/api';

function Casos() {
  const [casos, setCasos] = useState([]);
  const [tribunales, setTribunales] = useState([]);
  const [newCaso, setNewCaso] = useState({
    rit: '',
    tribunal_id: '',
    fecha_inicio: '',
    estado: 'ACTIVA',
    descripcion: ''
  });

  // Cargar casos y tribunales al montar el componente
  useEffect(() => {
    fetchCasos();
    fetchTribunales();
  }, []);

  const fetchCasos = () => {
    apiFetch('/api/casos')
      .then(data => setCasos(data))
      .catch(error => console.error('Error al obtener casos:', error));
  };

  const fetchTribunales = () => {
    apiFetch('/api/casos/tribunales')
      .then(data => setTribunales(data))
      .catch(error => console.error('Error al obtener tribunales:', error));
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewCaso(prevState => ({ ...prevState, [name]: value }));
  };

  const handleCreateCaso = async (e) => {
    e.preventDefault();
    const payload = {
        rit: newCaso.rit,
        tribunal_id: parseInt(newCaso.tribunal_id, 10),
        fecha_inicio: newCaso.fecha_inicio,
        estado: newCaso.estado,
        descripcion: newCaso.descripcion
    };

    try {
        await apiFetch('/api/casos', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
        fetchCasos(); // Recargar la lista de casos
        setNewCaso({ rit: '', tribunal_id: '', fecha_inicio: '', estado: 'ACTIVA', descripcion: '' }); // Limpiar formulario
    } catch (error) {
        if (error.message.includes('409')) {
            alert('Error al crear caso: Ya existe un caso con el mismo RIT.');
        } else {
            console.error('Error al crear caso:', error);
            alert('Error al crear caso. Por favor, revise la consola para más detalles.');
        }
    }
  };

  const handleDeleteCaso = (id) => {
    apiFetch(`/api/casos/${id}`, {
      method: 'DELETE',
    })
      .then(() => {
        setCasos(prevCasos => prevCasos.filter(caso => caso.id_causa !== id));
      })
      .catch(error => console.error('Error al eliminar caso:', error));
  };

  return (
    <div>
      <h2>Gestión de Casos</h2>

      {/* Formulario para crear nuevo caso */}
      <div className="card mb-4">
        <div className="card-header">Crear Nuevo Caso</div>
        <div className="card-body">
          <form onSubmit={handleCreateCaso}>
            <div className="row mb-3">
              <div className="col-md-6">
                <label htmlFor="rit" className="form-label">RIT</label>
                <input type="text" className="form-control" id="rit" name="rit" placeholder="Ej: C-123-2024" value={newCaso.rit} onChange={handleInputChange} required />
              </div>
              <div className="col-md-6">
                <label htmlFor="tribunal_id" className="form-label">Tribunal</label>
                <select className="form-select" id="tribunal_id" name="tribunal_id" value={newCaso.tribunal_id} onChange={handleInputChange} required>
                  <option value="" disabled>Seleccione un tribunal...</option>
                  {tribunales.map(t => (
                    <option key={t.id_tribunal} value={t.id_tribunal}>{t.nombre}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="row mb-3">
              <div className="col-md-6">
                <label htmlFor="fecha_inicio" className="form-label">Fecha de Inicio</label>
                <input type="date" className="form-control" id="fecha_inicio" name="fecha_inicio" value={newCaso.fecha_inicio} onChange={handleInputChange} required />
              </div>
              <div className="col-md-6">
                <label htmlFor="estado" className="form-label">Estado</label>
                <select className="form-select" id="estado" name="estado" value={newCaso.estado} onChange={handleInputChange}>
                  <option value="ACTIVA">Activa</option>
                  <option value="CONGELADA">Congelada</option>
                  <option value="ARCHIVADA">Archivada</option>
                </select>
              </div>
            </div>
            <div className="mb-3">
                <label htmlFor="descripcion" className="form-label">Descripción</label>
                <textarea className="form-control" id="descripcion" name="descripcion" rows="3" value={newCaso.descripcion} onChange={handleInputChange}></textarea>
            </div>
            <button type="submit" className="btn btn-primary">Crear Caso</button>
          </form>
        </div>
      </div>

      {/* Búsqueda y listado de casos */}
      <div className="card">
        <div className="card-header">Listado de Casos</div>
        <div className="card-body">
          <table className="table">
            <thead>
              <tr>
                <th>ID Causa</th>
                <th>RIT</th>
                <th>Fecha Inicio</th>
                <th>Estado</th>
                <th>Descripción</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {casos.map(caso => (
                <tr key={caso.id_causa}>
                  <td>{caso.id_causa}</td>
                  <td>{caso.rit}</td>
                  <td>{caso.fecha_inicio ? new Date(caso.fecha_inicio).toLocaleDateString() : '-'}</td>
                  <td><span className={`badge bg-${caso.estado === 'ACTIVA' ? 'success' : caso.estado === 'CONGELADA' ? 'warning' : 'secondary'}`}>{caso.estado}</span></td>
                  <td>{caso.descripcion}</td>
                  <td>
                    <Link to={`/casos/${caso.id_causa}`} className="btn btn-info btn-sm me-2">Detalles</Link>
                    <button className="btn btn-danger btn-sm" onClick={() => handleDeleteCaso(caso.id_causa)}>Eliminar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default Casos;
