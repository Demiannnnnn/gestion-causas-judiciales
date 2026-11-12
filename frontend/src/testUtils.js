// Utilidades compartidas por los tests: genera JWT sin firmar con el payload dado.
const b64url = (obj) =>
  window.btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

export const fakeToken = (payload) => `${b64url({ alg: 'HS256', typ: 'JWT' })}.${b64url(payload)}.firma`;
