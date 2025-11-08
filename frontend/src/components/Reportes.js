import React, { useState, useEffect } from 'react';
import apiFetch from '../utils/api';

function Reportes() {
  const [estadisticas, setEstadisticas] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Cargar estadísticas al montar el componente
    cargarEstadisticas();
  }, []);

  const cargarEstadisticas = async () => {
    try {
      setLoading(true);
      const data = await apiFetch('/api/reportes/estadisticas');
      setEstadisticas(data);
    } catch (error) {
      console.error('Error al cargar estadísticas:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadReporte = (tipo) => {
    // Descargar el reporte
    const token = localStorage.getItem('token');
    const url = `/api/reportes/${tipo}`;
    
    // Crear un elemento 'a' temporal para descargar
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', '');
    
    // Si hay token, agregarlo como query param
    if (token) {
      link.href += `?token=${token}`;
    }
    
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div>
      <h2>Generación de Reportes</h2>
      
      {/* Estadísticas Generales */}
      {loading ? (
        <div className="text-center my-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Cargando...</span>
          </div>
        </div>
      ) : estadisticas && (
        <div className="row mb-4">
          <div className="col-md-3">
            <div className="card text-center border-primary">
              <div className="card-body">
                <h1 className="display-4 text-primary">{estadisticas.totales.casos}</h1>
                <p className="text-muted mb-0">Total de Casos</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center border-success">
              <div className="card-body">
                <h1 className="display-4 text-success">{estadisticas.totales.documentos}</h1>
                <p className="text-muted mb-0">Documentos</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center border-info">
              <div className="card-body">
                <h1 className="display-4 text-info">{estadisticas.totales.movimientos}</h1>
                <p className="text-muted mb-0">Movimientos</p>
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="card text-center border-warning">
              <div className="card-body">
                <h1 className="display-4 text-warning">{estadisticas.casos_por_estado.length}</h1>
                <p className="text-muted mb-0">Estados Activos</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Distribución por Estado */}
      {estadisticas && (
        <div className="row mb-4">
          <div className="col-md-6">
            <div className="card">
              <div className="card-header bg-primary text-white">
                <h5 className="mb-0">📊 Casos por Estado</h5>
              </div>
              <div className="card-body">
                <table className="table table-hover">
                  <thead>
                    <tr>
                      <th>Estado</th>
                      <th className="text-end">Cantidad</th>
                    </tr>
                  </thead>
                  <tbody>
                    {estadisticas.casos_por_estado.map((item, index) => (
                      <tr key={index}>
                        <td>
                          <span className={`badge bg-${
                            item.estado === 'ACTIVA' ? 'success' : 
                            item.estado === 'CONGELADA' ? 'warning' : 'secondary'
                          }`}>
                            {item.estado}
                          </span>
                        </td>
                        <td className="text-end">
                          <strong>{item.cantidad}</strong>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="col-md-6">
            <div className="card">
              <div className="card-header bg-success text-white">
                <h5 className="mb-0">📄 Documentos por Tipo</h5>
              </div>
              <div className="card-body">
                <table className="table table-hover">
                  <thead>
                    <tr>
                      <th>Tipo</th>
                      <th className="text-end">Cantidad</th>
                    </tr>
                  </thead>
                  <tbody>
                    {estadisticas.documentos_por_tipo.map((item, index) => (
                      <tr key={index}>
                        <td>{item.tipo}</td>
                        <td className="text-end">
                          <strong>{item.cantidad}</strong>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Casos por Tribunal */}
      {estadisticas && (
        <div className="row mb-4">
          <div className="col-md-12">
            <div className="card">
              <div className="card-header bg-info text-white">
                <h5 className="mb-0">🏛️ Casos por Tribunal</h5>
              </div>
              <div className="card-body">
                <table className="table table-hover">
                  <thead>
                    <tr>
                      <th>Tribunal</th>
                      <th className="text-end">Cantidad de Casos</th>
                    </tr>
                  </thead>
                  <tbody>
                    {estadisticas.casos_por_tribunal.map((item, index) => (
                      <tr key={index}>
                        <td>{item.tribunal}</td>
                        <td className="text-end">
                          <strong>{item.cantidad}</strong>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Botones de Descarga de Reportes */}
      <div className="card">
        <div className="card-header bg-dark text-white">
          <h5 className="mb-0">📥 Descargar Reportes</h5>
        </div>
        <div className="card-body">
          <p className="text-muted">
            Seleccione el tipo de reporte que desea generar y descargar en formato CSV.
          </p>
          
          <div className="row g-3">
            <div className="col-md-6">
              <div className="card h-100">
                <div className="card-body">
                  <h6 className="card-title">📋 Reporte de Casos</h6>
                  <p className="card-text text-muted">
                    Descarga un CSV con todos los casos del sistema, incluyendo RIT, estado, 
                    tribunal y descripción.
                  </p>
                  <button 
                    className="btn btn-primary w-100" 
                    onClick={() => handleDownloadReporte('casos')}
                  >
                    <i className="bi bi-download"></i> Descargar Casos (CSV)
                  </button>
                </div>
              </div>
            </div>

            <div className="col-md-6">
              <div className="card h-100">
                <div className="card-body">
                  <h6 className="card-title">📄 Reporte de Documentos</h6>
                  <p className="card-text text-muted">
                    Descarga un CSV con todos los documentos registrados, incluyendo nombre, 
                    tipo, fecha y caso asociado.
                  </p>
                  <button 
                    className="btn btn-success w-100" 
                    onClick={() => handleDownloadReporte('documentos')}
                  >
                    <i className="bi bi-download"></i> Descargar Documentos (CSV)
                  </button>
                </div>
              </div>
            </div>

            <div className="col-md-6">
              <div className="card h-100">
                <div className="card-body">
                  <h6 className="card-title">⏰ Reporte de Vencimientos</h6>
                  <p className="card-text text-muted">
                    Descarga un CSV con los casos que tienen vencimientos en los próximos 30 días.
                  </p>
                  <button 
                    className="btn btn-warning w-100" 
                    onClick={() => handleDownloadReporte('vencimientos')}
                  >
                    <i className="bi bi-download"></i> Descargar Vencimientos (CSV)
                  </button>
                </div>
              </div>
            </div>

            <div className="col-md-6">
              <div className="card h-100 border-info">
                <div className="card-body">
                  <h6 className="card-title">📊 Estadísticas Completas</h6>
                  <p className="card-text text-muted">
                    Actualizar las estadísticas mostradas en esta página.
                  </p>
                  <button 
                    className="btn btn-info w-100" 
                    onClick={cargarEstadisticas}
                  >
                    <i className="bi bi-arrow-clockwise"></i> Actualizar Estadísticas
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Información adicional */}
      <div className="alert alert-info mt-4" role="alert">
        <h6 className="alert-heading">ℹ️ Información sobre los Reportes</h6>
        <p className="mb-0">
          Los reportes se generan en formato CSV para fácil importación a Excel u otras herramientas de análisis. 
          Los archivos incluyen encabezados descriptivos y pueden ser filtrados según sus necesidades.
        </p>
      </div>
    </div>
  );
}

export default Reportes;