import React from 'react';
import './App.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import { BrowserRouter as Router, Route, Routes, Link, useNavigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';

// Importa los componentes
import Casos from './components/Casos';
import Documentos from './components/Documentos';
import Notificaciones from './components/Notificaciones';
import Reportes from './components/Reportes';
import Login from './components/Login';
import ProtectedRoute from './components/ProtectedRoute'; // Importar el guardia

function App() {
  const { isLoggedIn, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login'); // Redirigir a login después de cerrar sesión
  };

  return (
      <div className="App">
        <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
          <div className="container-fluid">
            <Link className="navbar-brand" to="/">Gestión Judicial</Link>
            <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
              <span className="navbar-toggler-icon"></span>
            </button>
            <div className="collapse navbar-collapse" id="navbarNav">
              <ul className="navbar-nav me-auto mb-2 mb-lg-0">
                <li className="nav-item">
                  <Link className="nav-link" to="/casos">Casos</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/documentos">Documentos</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/notificaciones">Notificaciones</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/reportes">Reportes</Link>
                </li>
              </ul>
              <div className="d-flex">
                {isLoggedIn ? (
                  <button className="btn btn-outline-secondary" onClick={handleLogout}>Logout</button>
                ) : (
                  <Link className="btn btn-outline-primary" to="/login">Login</Link>
                )}
              </div>
            </div>
          </div>
        </nav>

        <div className="container mt-4">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/login" element={<Login />} />
            
            {/* Rutas Protegidas */}
            <Route path="/casos" element={<ProtectedRoute><Casos /></ProtectedRoute>} />
            <Route path="/documentos" element={<ProtectedRoute><Documentos /></ProtectedRoute>} />
            <Route path="/notificaciones" element={<ProtectedRoute><Notificaciones /></ProtectedRoute>} />
            <Route path="/reportes" element={<ProtectedRoute><Reportes /></ProtectedRoute>} />
          </Routes>
        </div>
      </div>
  );
}

// El componente App debe estar envuelto en Router para usar useNavigate
function AppWrapper() {
  return (
    <Router>
      <App />
    </Router>
  );
}

function Home() {
  return (
    <div>
      <h2>Bienvenido al Sistema de Gestión Judicial</h2>
      <p>Seleccione una opción del menú para comenzar.</p>
    </div>
  );
}

export default AppWrapper;