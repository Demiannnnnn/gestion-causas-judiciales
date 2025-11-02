import React, { useState, useEffect } from 'react';

const API_URL = '/api'; // URL base del gateway Traefik

function Casos() {
  const [casos, setCasos] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [newCaso, setNewCaso] = useState({
    rit: '',
    tribunal_id: ''
  });

  // Cargar casos al montar el componente
  useEffect(() => {
    fetchCasos();
  }, []);

  const fetchCasos = () => {
    fetch(`/api/casos`)
      .then(response => response.json())
      .then(data => setCasos(data))
      .catch(error => console.error('Error al obtener casos:', error));
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
    // La búsqueda en el backend no está implementada aún con la nueva API
    // fetchCasos(e.target.value);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewCaso(prevState => ({ ...prevState, [name]: value }));
  };

  const handleCreateCaso = (e) => {
    e.preventDefault();
    const payload = {
        ...newCaso,
        tribunal_id: parseInt(newCaso.tribunal_id, 10) // Asegurarse que es un número
    };

    fetch(`/api/casos` , {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
      .then(response => response.json())
      .then(data => {
        fetchCasos(); // Recargar todos los casos para ver el nuevo
        setNewCaso({ rit: '', tribunal_id: '' }); // Limpiar formulario
      })
      .catch(error => console.error('Error al crear caso:', error));
  };

  const handleDeleteCaso = (id) => {
    fetch(`/api/casos/${id}`, {
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
              <div className="col">
                <input type="text" className="form-control" name="rit" placeholder="RIT" value={newCaso.rit} onChange={handleInputChange} required />
              </div>
              <div className="col">
                <input type="number" className="form-control" name="tribunal_id" placeholder="ID del Tribunal" value={newCaso.tribunal_id} onChange={handleInputChange} required />
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
                <th>ID Causa</th>
                <th>RIT</th>
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
                  <td><span className={`badge bg-${caso.estado === 'ACTIVA' ? 'success' : 'secondary'}`}>{caso.estado}</span></td>
                  <td>{caso.descripcion}</td>
                  <td>
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