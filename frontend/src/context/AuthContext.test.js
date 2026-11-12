import { act, render, screen } from '@testing-library/react';
import { AuthProvider, useAuth } from './AuthContext';
import { fakeToken } from '../testUtils';

let auth;
const Espia = () => {
  auth = useAuth();
  return <p>{auth.isLoggedIn ? `rol:${auth.userRole}` : 'anónimo'}</p>;
};

const renderProvider = () =>
  render(
    <AuthProvider>
      <Espia />
    </AuthProvider>
  );

describe('AuthContext', () => {
  beforeEach(() => localStorage.clear());

  test('arranca anónimo sin token guardado', () => {
    renderProvider();
    expect(screen.getByText('anónimo')).toBeInTheDocument();
    expect(auth.userRole).toBeNull();
  });

  test('recupera la sesión desde localStorage', () => {
    localStorage.setItem('token', fakeToken({ rol: 'ADMINISTRADOR' }));
    renderProvider();
    expect(screen.getByText('rol:ADMINISTRADOR')).toBeInTheDocument();
  });

  test('login guarda el token y logout lo elimina', () => {
    renderProvider();
    const token = fakeToken({ rol: 'ABOGADO' });
    act(() => auth.login(token));
    expect(localStorage.getItem('token')).toBe(token);
    expect(screen.getByText('rol:ABOGADO')).toBeInTheDocument();

    act(() => auth.logout());
    expect(localStorage.getItem('token')).toBeNull();
    expect(screen.getByText('anónimo')).toBeInTheDocument();
  });
});
