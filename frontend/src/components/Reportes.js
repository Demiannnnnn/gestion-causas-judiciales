import React from 'react';

function Reportes() {

  const handleDownloadReporte = (tipo) => {
    // Se asume que el backend genera el reporte y lo devuelve como un archivo para descargar
    window.open(`/api/reportes/${tipo}`);
  };

  return (
    <div>
      <h2>Generación de Reportes</h2>
      <p>Seleccione el tipo de reporte que desea generar y descargar.</p>
      
      <div className="d-grid gap-2 col-6 mx-auto">
        <button className="btn btn-primary" type="button" onClick={() => handleDownloadReporte('casos')}>
          Generar Reporte de Casos (CSV)
        </button>
        <button className="btn btn-secondary" type="button" onClick={() => handleDownloadReporte('documentos')}>
          Generar Reporte de Documentos (CSV)
        </button>
      </div>
    </div>
  );
}

export default Reportes;
