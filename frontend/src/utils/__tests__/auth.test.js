import { parseJwt, getUserRole } from '../auth';
import { fakeToken } from '../../testUtils';

describe('parseJwt', () => {
  test('decodifica el payload del token', () => {
    const token = fakeToken({ id_usuario: 7, rol: 'ABOGADO' });
    expect(parseJwt(token)).toEqual({ id_usuario: 7, rol: 'ABOGADO' });
  });

  test('soporta caracteres UTF-8 en el payload', () => {
    const payload = { nombre: 'Peña' };
    const utf8 = unescape(encodeURIComponent(JSON.stringify(payload)));
    const body = window.btoa(utf8).replace(/=+$/, '');
    expect(parseJwt(`x.${body}.y`)).toEqual(payload);
  });

  test('devuelve null sin token o con token malformado', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(parseJwt(null)).toBeNull();
    expect(parseJwt('')).toBeNull();
    expect(parseJwt('no-es-un-jwt')).toBeNull();
    expect(parseJwt('a.%%%.c')).toBeNull();
    spy.mockRestore();
  });
});

describe('getUserRole', () => {
  test('extrae el rol', () => {
    expect(getUserRole(fakeToken({ rol: 'SISTEMAS' }))).toBe('SISTEMAS');
  });

  test('devuelve null si no hay token', () => {
    expect(getUserRole(null)).toBeNull();
  });
});
