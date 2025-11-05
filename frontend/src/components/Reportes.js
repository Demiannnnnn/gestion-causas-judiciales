import React, { useState, useEffect } from 'react';
import apiFetch from '../utils/api';

function Reportes() {
  const [tribunales, setTribunales] = useState([]);
  const [selectedTribunal, setSelectedTribunal] = useState("");

  useEffect(() => {
    fetchTribunales();
  }, []);

  const fetchTribunales = () => {
    apiFetch('/api/casos/tribunales')
      .then(data => setTribunales(data))
      .catch(error => console.error('Error al obtener tribunales:', error));
  };

  const handleDownloadReporte = (tipo) => {
    let url = `/api/reportes/${tipo}`;
    if (tipo === 'casos' && selectedTribunal) {
      url += `?tribunal_id=${selectedTribunal}`;
    }
    window.open(url);
  };

  return (
    <div>
      <h2>Generación de Reportes</h2>
      <p>Seleccione el tipo de reporte que desea generar y descargar.</p>

      <div className="row mb-3">
        <div className="col-md-6">
          <label htmlFor="tribunal" className="form-label">Filtrar por Tribunal</label>
          <select id="tribunal" className="form-select" value={selectedTribunal} onChange={(e) => setSelectedTribunal(e.target.value)}>
            <option value="">Todos</option>
            {tribunales.map(t => (
              <option key={t.id_tribunal} value={t.id_tribunal}>{t.nombre}</option>
            ))}
          </select>
        </div>
      </div>
      
      <div className="d-grid gap-2 col-6 mx-auto">
        <button className="btn btn-primary" type="button" onClick={() => handleDownloadReporte('casos')}>
          Generar Reporte de Casos (CSV)
        </button>
        <button className="btn btn-secondary" type="button" onClick={() => handleDownloadReporte('vencimientos')}>
          Generar Reporte de Vencimientos (CSV)
        </button>
      </div>
    </div>
  );
}

export default Reportes;
