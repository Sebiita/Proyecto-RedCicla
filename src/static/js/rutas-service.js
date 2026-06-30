const RutasService = (() => {
    const API_BASE_URL = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/rutas'
        : '/rutas';

    async function _request(endpoint, opciones = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            ...opciones,
        };
        try {
            const response = await fetch(url, config);
            const data = await response.json();
            if (!response.ok) {
                const errorMsg = data.detail || data.error || `Error HTTP ${response.status}`;
                return { error: errorMsg };
            }
            return data;
        } catch (error) {
            return { error: `Error de conexión: ${error.message}` };
        }
    }

    async function crear(ruta) {
        return await _request('/registrar', {
            method: 'POST',
            body: JSON.stringify(ruta),
        });
    }

    async function obtenerTodas() {
        const resultado = await _request('/listar');
        if (resultado.error) return [];
        return resultado.rutas || [];
    }

    async function obtenerPorId(id) {
        const resultado = await _request(`/obtener/${id}`);
        if (resultado.error) return null;
        return resultado.ruta || null;
    }

    async function actualizar(id, datos) {
        return await _request(`/actualizar/${id}`, {
            method: 'PUT',
            body: JSON.stringify(datos),
        });
    }

    async function eliminar(id) {
        return await _request(`/eliminar/${id}`, {
            method: 'DELETE',
        });
    }

    return { crear, obtenerTodas, obtenerPorId, actualizar, eliminar };
})();
