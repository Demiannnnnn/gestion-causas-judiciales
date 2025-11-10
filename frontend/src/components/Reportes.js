import React, { useState, useEffect } from 'react';
import apiFetch from '../utils/api';

function Reportes() {
  const [tribunales, setTribunales] = useState([]);
  const [casos, setCasos] = useState([]);
  const [estadisticas, setEstadisticas] = useState(null);
  const [loading, setLoading] = useState(false);
  
  // Filtros para reportes
  const [filtroTribunal, setFiltroTribunal] = useState('');
  const [filtroEstado, setFiltroEstado] = useState('');
  const [diasVencimiento, setDiasVencimiento] = useState(30);
  const [casoSeleccionado, setCasoSeleccionado] = useState('');

  useEffect(() => {
    cargarDatos();
  }, []);

  const cargarDatos = async () => {
    try {
      // Cargar tribunales
      const tribunalesData = await apiFetch('/api/casos/tribunales');
      setTribunales(tribunalesData);
      
      // Cargar casos
      const casosData = await apiFetch('/api/casos');
      setCasos(casosData);
      
      // Cargar estadísticas
      const statsData = await apiFetch('/api/reportes/estadisticas');
      setEstadisticas(statsData);
    } catch (error) {
      console.error('Error al cargar datos:', error);
    }
  };

  const descargarReporteCasos = async () => {
    setLoading(true);
    try {
      let url = '/api/reportes/casos?';
      if (filtroTribunal) url += `tribunal_id=${filtroTribunal}&`;
      if (filtroEstado) url += `estado=${filtroEstado}`;
      
      // Descargar usando fetch directo para manejar archivos
      const token = localStorage.getItem('token');
      const response = await fetch(url, {
        headers: token ? { 'Authorization': `Bearer ${token}` } : {}
      });
      
      if (!response.ok) throw new Error('Error al descargar reporte');
      
      const blob = await response.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `reporte_casos_${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(downloadUrl);
      
      alert('Reporte descargado exitosamente');
    } catch (error) {
      console.error('Error al descargar reporte:', error);
      alert('Error al generar el reporte');
    } finally {
      setLoading(false);
    }
  };

  const descargarReporteVencimientos = async () => {
    setLoading(true);
    try {
      const url = `/api/reportes/vencimientos?dias=${diasVencimiento}`;
      
      const token = localStorage.getItem('token');
      const response = await fetch(url, {
        headers: token ? { 'Authorization': `Bearer ${token}` } : {}
      });
      
      if (!response.ok) throw new Error('Error al descargar reporte');
      
      const blob = await response.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `reporte_vencimientos_${diasVencimiento}dias.csv`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(downloadUrl);
      
      alert('Reporte de vencimientos descargado exitosamente');
    } catch (error) {
      console.error('Error al descargar reporte:', error);
      alert('Error al generar el reporte');
    } finally {
      setLoading(false);
    }
  };

  const descargarPDFCaso = async () => {
    if (!casoSeleccionado) {
      alert('Por favor seleccione un caso');
      return;
    }
    
    setLoading(true);
    try {
      const url = `/api/reportes/causa-history/${casoSeleccionado}/pdf`;
      
      const token = localStorage.getItem('token');
      const response = await fetch(url, {
        headers: token ? { 'Authorization': `Bearer ${token}` } : {}
      });
      
      if (!response.ok) throw new Error('Error al descargar PDF');
      
      const blob = await response.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `caso_${casoSeleccionado}_completo.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(downloadUrl);
      
      alert('PDF descargado exitosamente');
    } catch (error) {
      console.error('Error al descargar PDF:', error);
      alert('Error al generar el PDF');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>Generación de Reportes</h2>
      <p className="text-muted">
        Seleccione el tipo de reporte que desea generar. Los reportes se descargarán automáticamente.
      </p>

      {/* Estadísticas Generales */}
      {estadisticas && (
        <div className="row mb-4">
          <div className="col-md-12">
            <div className="card">
              <div className="card-header bg-primary text-white">
                📊 Estadísticas del Sistema
              </div>
              <div className="card-body">
                <div className="row">
                  <div className="col-md-3">
                    <div className="text-center">
                      <h4>{estadisticas.casos.total}</h4>
                      <p className="text-muted">Total Casos</p>
                    </div>
                  </div>
                  <div className="col-md-3">
                    <div className="text-center">
                      <h4 className="text-success">{estadisticas.casos.activos}</h4>
                      <p className="text-muted">Casos Activos</p>
                    </div>
                  </div>
                  <div className="col-md-3">
                    <div className="text-center">
                      <h4>{estadisticas.documentos_total}</h4>
                      <p className="text-muted">Documentos</p>
                    </div>
                  </div>
                  <div className="col-md-3">
                    <div className="text-center">
                      <h4>{estadisticas.movimientos_ultimos_30_dias}</h4>
                      <p className="text-muted">Movimientos (30 días)</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* RF6.1: Reporte de Estado de Causas */}
      <div className="card mb-4">
        <div className="card-header bg-info text-white">
          📋 RF6.1: Reporte de Estado de Causas por Tribunal/Abogado
        </div>
        <div className="card-body">
          <div className="row mb-3">
            <div className="col-md-6">
              <label className="form-label">Filtrar por Tribunal (Opcional)</label>
              <select 
                className="form-select" 
                value={filtroTribunal}
                onChange={(e) => setFiltroTribunal(e.target.value)}
              >
                <option value="">Todos los tribunales</option>
                {tribunales.map(t => (
                  <option key={t.id_tribunal} value={t.id_tribunal}>
                    {t.nombre}
                  </option>
                ))}
              </select>
            </div>
            <div className="col-md-6">
              <label className="form-label">Filtrar por Estado (Opcional)</label>
              <select 
                className="form-select"
                value={filtroEstado}
                onChange={(e) => setFiltroEstado(e.target.value)}
              >
                <option value="">Todos los estados</option>
                <option value="ACTIVA">Activa</option>
                <option value="CONGELADA">Congelada</option>
                <option value="ARCHIVADA">Archivada</option>
              </select>
            </div>
          </div>
          <button 
            className="btn btn-primary"
            onClick={descargarReporteCasos}
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                Generando...
              </>
            ) : (
              <>📥 Descargar Reporte CSV</>
            )}
          </button>
          <p className="text-muted mt-2 mb-0">
            <small>Genera un archivo CSV con todas las causas según los filtros seleccionados.</small>
          </p>
        </div>
      </div>

      {/* RF6.2: Reporte de Vencimientos */}
      <div className="card mb-4">
        <div className="card-header bg-warning">
          ⚠️ RF6.2: Reporte de Vencimiento de Plazos
        </div>
        <div className="card-body">
          <div className="row mb-3">
            <div className="col-md-6">
              <label className="form-label">Próximos Días</label>
              <input 
                type="number" 
                className="form-control"
                min="1"
                max="365"
                value={diasVencimiento}
                onChange={(e) => setDiasVencimiento(e.target.value)}
              />
              <small className="text-muted">
                Genera reporte de vencimientos para los próximos {diasVencimiento} días
              </small>
            </div>
          </div>
          <button 
            className="btn btn-warning"
            onClick={descargarReporteVencimientos}
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                Generando...
              </>
            ) : (
              <>📥 Descargar Reporte de Vencimientos (CSV)</>
            )}
          </button>
          <p className="text-muted mt-2 mb-0">
            <small>Genera un CSV con todos los vencimientos de plazos próximos.</small>
          </p>
        </div>
      </div>

      {/* RF6.3: Historial Completo en PDF */}
      <div className="card mb-4">
        <div className="card-header bg-danger text-white">
          📄 RF6.3: Exportar Historial Completo de Causa (PDF)
        </div>
        <div className="card-body">
          <div className="row mb-3">
            <div className="col-md-8">
              <label className="form-label">Seleccionar Caso</label>
              <select 
                className="form-select"
                value={casoSeleccionado}
                onChange={(e) => setCasoSeleccionado(e.target.value)}
              >
                <option value="">Seleccione un caso...</option>
                {casos.map(caso => (
                  <option key={caso.id_causa} value={caso.id_causa}>
                    {caso.rit} - {caso.descripcion || 'Sin descripción'}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <button 
            className="btn btn-danger"
            onClick={descargarPDFCaso}
            disabled={loading || !casoSeleccionado}
          >
            {loading ? (
              <>
                <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                Generando PDF...
              </>
            ) : (
              <>📥 Descargar PDF Completo</>
            )}
          </button>
          <p className="text-muted mt-2 mb-0">
            <small>
              Genera un PDF completo con toda la información del caso: partes, movimientos, documentos.
            </small>
          </p>
        </div>
      </div>

      {/* Información adicional */}
      <div className="alert alert-info" role="alert">
        <h6 className="alert-heading">ℹ️ Información sobre Reportes</h6>
        <ul className="mb-0">
          <li><strong>RF6.1:</strong> Reportes de casos permiten filtrar por tribunal y estado</li>
          <li><strong>RF6.2:</strong> Reportes de vencimientos alertan sobre plazos próximos a vencer</li>
          <li><strong>RF6.3:</strong> PDF completo incluye toda la información histórica de la causa</li>
          <li>Todos los reportes se descargan automáticamente al hacer clic</li>
        </ul>
      </div>
    </div>
  );
}

export default Reportes;