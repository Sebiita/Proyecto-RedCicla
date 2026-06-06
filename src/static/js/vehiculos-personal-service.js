/**
 * CamionesService — Capa de servicio para camiones (vehículos).
 *
 * Conecta el frontend con el backend FastAPI.
 * Endpoints del backend:
 *   POST   /camiones/registrar            → Crear camión
 *   GET    /camiones/obtener              → Listar todos los camiones
 *   GET    /camiones/obtener/{patente}    → Obtener camión por patente
 *   PUT    /camiones/actualizar/{patente} → Actualizar camión
 *   DELETE /camiones/eliminar/{patente}   → Eliminar camión
 */
const CamionesService = (() => {
    const API_BASE_URL = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/camiones'
        : '/camiones';

    async function _request(endpoint, opciones = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        const config = {
            headers: { 'Content-Type': 'application/json' },
            ...opciones,
        };
        try {
            const response = await fetch(url, config);
            const data = await response.json();
            if (!response.ok) {
                const errorMsg = data.detail || data.error || `Error HTTP ${response.status}`;
                console.error(`CamionesService Error [${response.status}]:`, errorMsg);
                return { error: errorMsg };
            }
            return data;
        } catch (error) {
            console.error('CamionesService Error de red:', error);
            return { error: `Error de conexión: ${error.message}. ¿Está el servidor ejecutándose?` };
        }
    }

    async function registrar(camion) {
        return await _request('/registrar', {
            method: 'POST',
            body: JSON.stringify(camion),
        });
    }

    async function obtenerTodos() {
        const resultado = await _request('/obtener');
        if (resultado.error) {
            console.error('Error al obtener camiones:', resultado.error);
            return [];
        }
        return resultado.camiones || [];
    }

    async function obtenerPorPatente(patente) {
        const resultado = await _request(`/obtener/${encodeURIComponent(patente)}`);
        if (resultado.error) return null;
        return resultado.camion || null;
    }

    async function actualizar(patente, datosActualizados) {
        return await _request(`/actualizar/${encodeURIComponent(patente)}`, {
            method: 'PUT',
            body: JSON.stringify(datosActualizados),
        });
    }

    async function eliminar(patente) {
        return await _request(`/eliminar/${encodeURIComponent(patente)}`, {
            method: 'DELETE',
        });
    }

    return { registrar, obtenerTodos, obtenerPorPatente, actualizar, eliminar };
})();


/**
 * PersonalService — Capa de servicio para personal operativo (Choferes y Ayudantes).
 *
 * Conecta el frontend con el backend FastAPI.
 * Endpoints del backend:
 *   POST   /usuarios/registrar           → Crear usuario
 *   GET    /usuarios/obtener             → Listar todos los usuarios
 *   GET    /usuarios/obtener/{correo}    → Obtener usuario por correo
 *   PUT    /usuarios/actualizar/{correo} → Actualizar usuario
 *   DELETE /usuarios/eliminar            → Eliminar usuario
 */
const PersonalService = (() => {
    const API_BASE_URL = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/usuarios'
        : '/usuarios';

    async function _request(endpoint, opciones = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        const config = {
            headers: { 'Content-Type': 'application/json' },
            ...opciones,
        };
        try {
            const response = await fetch(url, config);
            const data = await response.json();
            if (!response.ok) {
                const errorMsg = data.detail || data.error || `Error HTTP ${response.status}`;
                console.error(`PersonalService Error [${response.status}]:`, errorMsg);
                return { error: errorMsg };
            }
            return data;
        } catch (error) {
            console.error('PersonalService Error de red:', error);
            return { error: `Error de conexión: ${error.message}. ¿Está el servidor ejecutándose?` };
        }
    }

    async function registrar(usuario) {
        return await _request('/registrar', {
            method: 'POST',
            body: JSON.stringify(usuario),
        });
    }

    async function obtenerTodos() {
        const resultado = await _request('/obtener');
        if (resultado.error) {
            console.error('Error al obtener usuarios:', resultado.error);
            return [];
        }
        return resultado.usuarios || [];
    }

    /** Filtra solo Chofer y Ayudante del total */
    async function obtenerPersonalOperativo() {
        const todos = await obtenerTodos();
        return todos.filter(u => u.rol === 'Chofer' || u.rol === 'Ayudante');
    }

    async function obtenerPorCorreo(correo) {
        const resultado = await _request(`/obtener/${encodeURIComponent(correo)}`);
        if (resultado.error) return null;
        return resultado.usuario || null;
    }

    async function actualizar(correo, datosActualizados) {
        return await _request(`/actualizar/${encodeURIComponent(correo)}`, {
            method: 'PUT',
            body: JSON.stringify(datosActualizados),
        });
    }

    async function eliminar(correo) {
        return await _request('/eliminar', {
            method: 'DELETE',
            body: JSON.stringify({ correo }),
        });
    }

    return { registrar, obtenerTodos, obtenerPersonalOperativo, obtenerPorCorreo, actualizar, eliminar };
})();
