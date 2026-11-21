import { render, screen } from '@testing-library/react';
import App from './App';
import { AuthProvider } from './context/AuthContext';

test('renders welcome heading on home route', () => {
  render(
    <AuthProvider>
      <App />
    </AuthProvider>
  );
  const headingElement = screen.getByText(/Bienvenido al Sistema de Gestión Judicial/i);
  expect(headingElement).toBeInTheDocument();
});
