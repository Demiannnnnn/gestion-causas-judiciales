import React from 'react';
import './App.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';

// Importa los componentes que crearás
import Casos from './components/Casos';
import Documentos from './components/Documentos';
import Notificaciones from './components/Notificaciones';
import Reportes from './components/Reportes';

function App() {
  return (
    <Router>
      <div className="App">
        <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
          <div className="container-fluid">
            <Link className="navbar-brand" to="/">Gestión Judicial</Link>
            <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
              <span className="navbar-toggler-icon"></span>
            </button>
            <div className="collapse navbar-collapse" id="navbarNav">
              <ul className="navbar-nav">
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
            </div>
          </div>
        </nav>

        <div className="container mt-4">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/casos" element={<Casos />} />
            <Route path="/documentos" element={<Documentos />} />
            <Route path="/notificaciones" element={<Notificaciones />} />
            <Route path="/reportes" element={<Reportes />} />
          </Routes>
        </div>
      </div>
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

export default App;