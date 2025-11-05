import React, { useState, useEffect } from 'react';
import apiFetch from '../utils/api';

function Documentos() {
  const [casos, setCasos] = useState([]);
  const [selectedCaso, setSelectedCaso] = useState('');
  const [documentos, setDocumentos] = useState([]);
  const [file, setFile] = useState(null);

  useEffect(() => {
    apiFetch('/api/casos')
      .then(data => setCasos(data))
      .catch(error => console.error('Error al obtener casos:', error));
  }, []);

  const fetchDocuments = () => {
    if (selectedCaso) {
      console.log('Fetching documents for case:', selectedCaso);
      apiFetch(`/api/documentos/causa/${selectedCaso}/documentos`)
        .then(data => {
          console.log('Received documents data:', data);
          setDocumentos(data);
        })
        .catch(error => {
          console.error('Error al obtener documentos:', error);
          setDocumentos([]);
        });
    }
  }

  useEffect(() => {
    if(selectedCaso) fetchDocuments();
    else setDocumentos([]);
  }, [selectedCaso]);

  const handleCasoChange = (e) => {
    setSelectedCaso(e.target.value);
  };

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = (e) => {
    e.preventDefault();
    if (!file || !selectedCaso) {
      alert('Por favor, seleccione un caso y un archivo.');
      return;
    }

    const formData = new FormData();
    formData.append('file', file);

    apiFetch(`/api/documentos/causa/${selectedCaso}/documentos`, {
      method: 'POST',
      body: formData,
    })
      .then(() => {
        alert('Archivo subido con éxito');
        fetchDocuments(); // Recargar la lista de documentos
        setFile(null); // Limpiar el input de archivo
        e.target.reset(); // Limpiar el formulario
      })
      .catch(error => console.error('Error al subir archivo:', error));
  };

  const handleDelete = (id_documento) => {
    if (window.confirm('¿Está seguro de que desea eliminar este documento?')) {
      apiFetch(`/api/documentos/${id_documento}`, {
        method: 'DELETE',
      })
        .then(() => {
          alert('Documento eliminado con éxito');
          fetchDocuments(); // Recargar la lista de documentos
        })
        .catch(error => console.error('Error al eliminar documento:', error));
    }
  };

  const handleDownload = (id_documento) => {
    window.open(`/api/documentos/${id_documento}`);
  };

  return (
    <div>
      <h2>Gestión de Documentos</h2>
      
      <div className="mb-3">
        <label htmlFor="caso-selector" className="form-label">Seleccione un Caso</label>
        <select id="caso-selector" className="form-select" value={selectedCaso} onChange={handleCasoChange}>
          <option value="">Seleccione un caso...</option>
          {casos.map(caso => (
            <option key={caso.id_causa} value={caso.id_causa}>
              {caso.rit} - {caso.descripcion}
            </option>
          ))}
        </select>
      </div>

      {selectedCaso && (
        <div>
          <div className="card mb-4">
            <div className="card-header">Subir Nuevo Documento</div>
            <div className="card-body">
              <form onSubmit={handleUpload}>
                <div className="mb-3">
                  <label htmlFor="file-input" className="form-label">Seleccionar Archivo PDF</label>
                  <input id="file-input" type="file" className="form-control" onChange={handleFileChange} accept=".pdf" required />
                </div>
                <button type="submit" className="btn btn-primary">Subir Documento</button>
              </form>
            </div>
          </div>

          <div className="card">
            <div className="card-header">Documentos del Caso</div>
            <div className="card-body">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID Documento</th>
                    <th>Nombre del Archivo</th>
                    <th>Fecha de Subida</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {documentos.map(doc => (
                    <tr key={doc.id_documento}>
                      <td>{doc.id_documento}</td>
                      <td>{doc.nombre_archivo}</td>
                      <td>{new Date(doc.fecha_subida).toLocaleString()}</td>
                      <td>
                        <button className="btn btn-success btn-sm me-2" onClick={() => handleDownload(doc.id_documento)}>Descargar</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(doc.id_documento)}>Eliminar</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Documentos;
