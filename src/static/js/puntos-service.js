/**
 * PuntosService — Capa de servicio para puntos de reciclaje.
 *
 * Conecta el frontend con el backend FastAPI.
 * Endpoints del backend:
 *   POST   /puntos/registrar         → Crear punto
 *   GET    /puntos/obtener           → Listar todos los puntos
 *   GET    /puntos/obtener/{id}      → Obtener punto por ID
 *   PUT    /puntos/actualizar/{id}   → Actualizar punto
 *   DELETE /puntos/eliminar/{id}     → Eliminar punto
 *
 * Modelo de datos del backend (PuntoRecicljeCrear):
 *   - municipalidad: string (nombre/municipalidad del punto)
 *   - latitud: float
 *   - longitud: float
 *   - estado: string ("Activo", "Inactivo", "Mantencion")
 *   - urgencia: string ("Baja", "Normal", "Alta", "Crítica")
 *   - capacidad_maxima: float (> 0)
 *   - capacidad_ocupada: float (>= 0)
 *
 * Modelo de respuesta (incluye además):
 *   - id: int (asignado por el backend)
 */

const PuntosService = (() => {
    // ========== CONFIGURACIÓN ==========
    // URL base del API FastAPI
    // Si se abre el HTML desde el servidor FastAPI (/static/), usar ruta relativa
    // Si se abre como archivo local, usar URL absoluta
    const API_BASE_URL = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/puntos'
        : '/puntos';

    // ========== FUNCIONES AUXILIARES ==========

    /**
     * Realiza una petición HTTP al backend.
     * @param {string} endpoint — Ruta relativa (ej: '/registrar')
     * @param {Object} opciones — Opciones de fetch (method, body, etc.)
     * @returns {Promise<Object>} — Respuesta JSON del backend
     */
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
                // FastAPI devuelve errores en formato { detail: "..." }
                const errorMsg = data.detail || data.error || `Error HTTP ${response.status}`;
                console.error(`PuntosService Error [${response.status}]:`, errorMsg);
                return { error: errorMsg };
            }

            return data;
        } catch (error) {
            console.error('PuntosService Error de red:', error);
            return { error: `Error de conexión: ${error.message}. ¿Está el servidor ejecutándose?` };
        }
    }

    // ========== API PÚBLICA ==========

    /**
     * Guarda un nuevo punto de reciclaje en el backend.
     * @param {Object} punto — Datos del punto (campos del modelo PuntoRecicljeCrear)
     * @returns {Promise<Object>} — { mensaje, punto } o { error }
     *
     * El backend espera:
     *   { municipalidad, latitud, longitud, estado, urgencia, capacidad_maxima, capacidad_ocupada }
     */
    async function guardar(punto) {
        return await _request('/registrar', {
            method: 'POST',
            body: JSON.stringify(punto),
        });
    }

    /**
     * Obtiene todos los puntos de reciclaje del backend.
     * @returns {Promise<Array>} — Lista de todos los puntos
     *
     * Respuesta del backend: { puntos: [...] }
     */
    async function obtenerTodos() {
        const resultado = await _request('/obtener');
        if (resultado.error) {
            console.error('Error al obtener puntos:', resultado.error);
            return [];
        }
        return resultado.puntos || [];
    }

    /**
     * Obtiene un punto por su ID.
     * @param {number} id — ID numérico del punto
     * @returns {Promise<Object|null>} — El punto o null si no existe
     *
     * Respuesta del backend: { punto: {...} }
     */
    async function obtenerPorId(id) {
        const resultado = await _request(`/obtener/${id}`);
        if (resultado.error) return null;
        return resultado.punto || null;
    }

    /**
     * Actualiza un punto existente.
     * @param {number} id — ID del punto a actualizar
     * @param {Object} datosActualizados — Campos a actualizar (parcial)
     * @returns {Promise<Object>} — { mensaje } o { error }
     */
    async function actualizar(id, datosActualizados) {
        return await _request(`/actualizar/${id}`, {
            method: 'PUT',
            body: JSON.stringify(datosActualizados),
        });
    }

    /**
     * Elimina un punto por su ID.
     * @param {number} id — ID del punto a eliminar
     * @returns {Promise<Object>} — { mensaje } o { error }
     */
    async function eliminar(id) {
        return await _request(`/eliminar/${id}`, {
            method: 'DELETE',
        });
    }

    /**
     * Obtiene solo los puntos activos.
     * @returns {Promise<Array>} — Lista de puntos con estado "Activo"
     */
    async function obtenerActivos() {
        const todos = await obtenerTodos();
        return todos.filter(p => p.estado === 'Activo');
    }

    // ========== EXPOSICIÓN DEL MÓDULO ==========
    return {
        guardar,
        obtenerTodos,
        obtenerPorId,
        actualizar,
        eliminar,
        obtenerActivos,
        API_BASE_URL
    };
})();
