const apiFetch = async (url, options = {}) => {
    const token = localStorage.getItem('token');

    const headers = {
        'Content-Type': 'application/json',
        ...options.headers, // Permite sobreescribir o añadir cabeceras
    };

    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
        ...options,
        headers,
    });

    // Si el token es inválido o expiró, el servidor debería devolver 401
    if (response.status === 401) {
        // Limpiar token y recargar la página para redirigir a login
        localStorage.removeItem('token');
        window.location.reload();
        throw new Error('Sesión expirada');
    }

    if (!response.ok) {
        // Para otros errores, intentar obtener un mensaje del cuerpo de la respuesta
        const errorData = await response.json().catch(() => ({ message: response.statusText }));
        throw new Error(errorData.message || 'Error en la petición a la API');
    }

    // Si la respuesta no tiene contenido (ej. en un DELETE), devolver un objeto vacío
    const contentType = response.headers.get("content-type");
    if (contentType && contentType.indexOf("application/json") !== -1) {
        return response.json();
    }
    return {};
};

export default apiFetch;
