import apiFetch from '../api';

const jsonResponse = (body, { status = 200, contentType = 'application/json' } = {}) => ({
  status,
  ok: status >= 200 && status < 300,
  statusText: 'Estado ' + status,
  headers: { get: () => contentType },
  json: () => Promise.resolve(body),
});

describe('apiFetch', () => {
  const originalLocation = window.location;

  beforeEach(() => {
    global.fetch = jest.fn();
    localStorage.clear();
    delete window.location;
    window.location = { reload: jest.fn() };
  });

  afterEach(() => {
    window.location = originalLocation;
  });

  test('agrega Authorization y Content-Type JSON', async () => {
    localStorage.setItem('token', 'abc');
    fetch.mockResolvedValue(jsonResponse({ ok: 1 }));

    await expect(apiFetch('/api/casos', { method: 'POST', body: '{}' })).resolves.toEqual({ ok: 1 });
    const [, opts] = fetch.mock.calls[0];
    expect(opts.method).toBe('POST');
    expect(opts.headers).toEqual({ 'Content-Type': 'application/json', Authorization: 'Bearer abc' });
  });

  test('no fuerza Content-Type con FormData y omite Authorization sin token', async () => {
    fetch.mockResolvedValue(jsonResponse({}));
    await apiFetch('/api/documentos', { method: 'POST', body: new FormData() });
    const [, opts] = fetch.mock.calls[0];
    expect(opts.headers).toEqual({});
  });

  test('con 401 borra el token, recarga y lanza error', async () => {
    localStorage.setItem('token', 'vencido');
    fetch.mockResolvedValue(jsonResponse({}, { status: 401 }));
    await expect(apiFetch('/api/casos')).rejects.toThrow('Sesión expirada');
    expect(localStorage.getItem('token')).toBeNull();
    expect(window.location.reload).toHaveBeenCalled();
  });

  test('propaga el mensaje de error del backend', async () => {
    fetch.mockResolvedValue(jsonResponse({ message: 'RIT duplicado' }, { status: 409 }));
    await expect(apiFetch('/api/casos')).rejects.toThrow('RIT duplicado');
  });

  test('usa statusText si la respuesta de error no es JSON', async () => {
    fetch.mockResolvedValue({
      ...jsonResponse(null, { status: 500 }),
      json: () => Promise.reject(new Error('no json')),
    });
    await expect(apiFetch('/api/casos')).rejects.toThrow('Estado 500');
  });

  test('devuelve objeto vacío si la respuesta no es JSON', async () => {
    fetch.mockResolvedValue(jsonResponse(null, { contentType: 'text/csv' }));
    await expect(apiFetch('/api/reportes/casos')).resolves.toEqual({});
  });
});
