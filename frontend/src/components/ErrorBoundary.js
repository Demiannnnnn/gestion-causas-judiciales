import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    // Actualiza el estado para que el siguiente renderizado muestre la UI alternativa
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    // También puedes registrar el error en un servicio de reporte de errores
    console.error("Error capturado por Error Boundary:", error, errorInfo);
    this.setState({ error, errorInfo });
  }

  render() {
    if (this.state.hasError) {
      // Puedes renderizar cualquier interfaz de repuesto personalizada
      return (
        <div className="container mt-5 text-center">
          <div className="alert alert-danger" role="alert">
            <h4 className="alert-heading">¡Ups! Algo salió mal.</h4>
            <p>
              La aplicación ha encontrado un error inesperado. Esto puede deberse a una alta carga en el servidor o un problema de conexión.
            </p>
            <hr />
            <p className="mb-0">
              Por favor, intenta recargar la página.
            </p>
            <button 
              className="btn btn-primary mt-3" 
              onClick={() => window.location.reload()}
            >
              Recargar Página
            </button>
            
            {/* Detalles técnicos solo para desarrollo (opcional) */}
            {process.env.NODE_ENV === 'development' && (
              <details className="mt-3 text-start">
                <summary>Detalles del error</summary>
                <pre>{this.state.error && this.state.error.toString()}</pre>
              </details>
            )}
          </div>
        </div>
      );
    }

    return this.props.children; 
  }
}

export default ErrorBoundary;
