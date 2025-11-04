import React from 'react';
import './App.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';

// Importa los componentes
import Casos from './components/Casos';
import CasoDetail from './components/CasoDetail'; // Importar el nuevo componente
import Documentos from './components/Documentos';
import Notificaciones from './components/Notificaciones';
import Reportes from './components/Reportes';
import Login from './components/Login';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout'; // Importar el nuevo Layout

function App() {
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          
          {/* Rutas Protegidas */}
          <Route path="/casos" element={<ProtectedRoute><Casos /></ProtectedRoute>} />
          <Route path="/casos/:id" element={<ProtectedRoute><CasoDetail /></ProtectedRoute>} /> {/* Nueva ruta */}
          <Route path="/documentos" element={<ProtectedRoute><Documentos /></ProtectedRoute>} />
          <Route path="/notificaciones" element={<ProtectedRoute><Notificaciones /></ProtectedRoute>} />
          <Route path="/reportes" element={<ProtectedRoute><Reportes /></ProtectedRoute>} />
        </Routes>
      </Layout>
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