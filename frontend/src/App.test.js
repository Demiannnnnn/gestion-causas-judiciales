import { render, screen } from '@testing-library/react';
import App from './App';
import { AuthProvider } from './context/AuthContext';
import { fakeToken } from './testUtils';

const renderApp = () =>
  render(
    <AuthProvider>
      <App />
    </AuthProvider>
  );

describe('App', () => {
  beforeEach(() => {
    localStorage.clear();
    window.history.pushState({}, '', '/');
  });

  test('muestra la página de inicio', () => {
    renderApp();
    expect(screen.getByText(/Bienvenido al Sistema de Gestión Judicial/i)).toBeInTheDocument();
  });

  test('el menú solo muestra IA Seguridad a roles de sistemas', () => {
    localStorage.setItem('token', fakeToken({ rol: 'ASISTENTE' }));
    renderApp();
    expect(screen.getByRole('link', { name: 'Casos' })).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Agente' })).not.toBeInTheDocument();
  });
});
