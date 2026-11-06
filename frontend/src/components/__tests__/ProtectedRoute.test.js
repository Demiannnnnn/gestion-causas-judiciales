import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import ProtectedRoute from '../ProtectedRoute';
import { AuthProvider } from '../../context/AuthContext';
import { fakeToken } from '../../testUtils';

const renderRuta = (allowedRoles) =>
  render(
    <AuthProvider>
      <MemoryRouter initialEntries={['/privado']}>
        <Routes>
          <Route path="/" element={<p>Inicio</p>} />
          <Route path="/login" element={<p>Pantalla de login</p>} />
          <Route
            path="/privado"
            element={
              <ProtectedRoute allowedRoles={allowedRoles}>
                <p>Contenido privado</p>
              </ProtectedRoute>
            }
          />
        </Routes>
      </MemoryRouter>
    </AuthProvider>
  );

describe('ProtectedRoute', () => {
  beforeEach(() => localStorage.clear());

  test('redirige a /login si no hay sesión', () => {
    renderRuta(['ABOGADO']);
    expect(screen.getByText('Pantalla de login')).toBeInTheDocument();
  });

  test('muestra el contenido si el rol está permitido', () => {
    localStorage.setItem('token', fakeToken({ rol: 'ABOGADO' }));
    renderRuta(['ADMINISTRADOR', 'ABOGADO']);
    expect(screen.getByText('Contenido privado')).toBeInTheDocument();
  });

  test('redirige al inicio si el rol no está permitido', () => {
    localStorage.setItem('token', fakeToken({ rol: 'ASISTENTE' }));
    renderRuta(['ADMINISTRADOR', 'SISTEMAS']);
    expect(screen.getByText('Inicio')).toBeInTheDocument();
  });

  test('sin allowedRoles basta con estar logueado', () => {
    localStorage.setItem('token', fakeToken({ rol: 'SISTEMAS' }));
    renderRuta(undefined);
    expect(screen.getByText('Contenido privado')).toBeInTheDocument();
  });
});
