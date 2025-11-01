import React, { useState, useEffect } from 'react';

const API_URL = '/api'; // URL base del gateway Traefik

function Casos() {
  const [casos, setCasos] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [newCaso, setNewCaso] = useState({
    rit: '',
    tribunal: '',
    partes: '',
    fecha_inicio: '',
    estado: 'Activo'
  });

  // Cargar casos al montar el componente
  useEffect(() => {
    fetchCasos();
  }, []);

  const fetchCasos = (query = '') => {
    fetch(`${API_URL}/casos?query=${query}`)
      .then(response => response.json())
      .then(data => setCasos(data))
      .catch(error => console.error('Error al obtener casos:', error));
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
    fetchCasos(e.target.value);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewCaso(prevState => ({ ...prevState, [name]: value }));
  };

  const handleCreateCaso = (e) => {
    e.preventDefault();
    fetch(`${API_URL}/casos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(newCaso),
    })
      .then(response => response.json())
      .then(data => {
        setCasos(prevCasos => [...prevCasos, data]);
        setNewCaso({ rit: '', tribunal: '', partes: '', fecha_inicio: '', estado: 'Activo' }); // Limpiar formulario
      })
      .catch(error => console.error('Error al crear caso:', error));
  };

  const handleDeleteCaso = (id) => {
    fetch(`${API_URL}/casos/${id}`, {
      method: 'DELETE',
    })
      .then(() => {
        setCasos(prevCasos => prevCasos.filter(caso => caso.id !== id));
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
              <div className="col">
                <input type="text" className="form-control" name="rit" placeholder="RIT" value={newCaso.rit} onChange={handleInputChange} required />
              </div>
              <div className="col">
                <input type="text" className="form-control" name="tribunal" placeholder="Tribunal" value={newCaso.tribunal} onChange={handleInputChange} required />
              </div>
            </div>
            <div className="row mb-3">
                <div className="col">
                    <input type="text" className="form-control" name="partes" placeholder="Partes" value={newCaso.partes} onChange={handleInputChange} required />
                </div>
                <div className="col">
                    <input type="date" className="form-control" name="fecha_inicio" value={newCaso.fecha_inicio} onChange={handleInputChange} required />
                </div>
                <div className="col">
                     <select className="form-select" name="estado" value={newCaso.estado} onChange={handleInputChange}>
                        <option value="Activo">Activo</option>
                        <option value="Archivado">Archivado</option>
                        <option value="Congelado">Congelado</option>
                    </select>
                </div>
            </div>
            <button type="submit" className="btn btn-primary">Crear Caso</button>
          </form>
        </div>
      </div>

      {/* Búsqueda y listado de casos */}
      <div className="card">
        <div className="card-header">Listado de Casos</div>
        <div className="card-body">
            <div class="input-group mb-3">
                <span class="input-group-text" id="basic-addon1">Buscar</span>
                <input type="text" className="form-control" placeholder="Buscar por RIT o tribunal..." value={searchTerm} onChange={handleSearchChange} />
            </div>
          
          <table className="table">
            <thead>
              <tr>
                <th>RIT</th>
                <th>Tribunal</th>
                <th>Partes</th>
                <th>Fecha de Inicio</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {casos.map(caso => (
                <tr key={caso.id}>
                  <td>{caso.rit}</td>
                  <td>{caso.tribunal}</td>
                  <td>{caso.partes}</td>
                  <td>{caso.fecha_inicio}</td>
                  <td><span className={`badge bg-${caso.estado === 'Activo' ? 'success' : 'secondary'}`}>{caso.estado}</span></td>
                  <td>
                    <button className="btn btn-danger btn-sm" onClick={() => handleDeleteCaso(caso.id)}>Eliminar</button>
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