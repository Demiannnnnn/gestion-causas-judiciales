import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Layout = ({ children }) => {
  const { isLoggedIn, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div>
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
            <div className="d-flex gap-2">
              {isLoggedIn ? (
                <>
                  <Link className="btn btn-outline-info" to="/ia-seguridad">Agente</Link>
                  <button className="btn btn-outline-secondary" onClick={handleLogout}>Logout</button>
                </>
              ) : (
                <Link className="btn btn-outline-primary" to="/login">Login</Link>
              )}
            </div>
          </div>
        </div>
      </nav>

      <div className="container mt-4">
        {children}
      </div>
    </div>
  );
};

export default Layout;
