/**
 * RutasService — Capa de servicio para rutas de recolección.
 *
 * Conecta el frontend con el backend FastAPI.
 * Endpoints del backend:
 *   POST   /rutas/registrar            → Crear ruta
 *   GET    /rutas/listar               → Listar todas las rutas
 *   GET    /rutas/obtener/{ruta_id}    → Obtener ruta por ID
 *   PUT    /rutas/actualizar/{ruta_id} → Actualizar ruta
 *   DELETE /rutas/eliminar/{ruta_id}   → Eliminar ruta
 *
 * Modelo de datos (RutaCrear):
 *   - fecha: string (YYYY-MM-DD)
 *   - camion_asignado: string (patente)
 *   - chofer_asignado: string (correo del chofer)
 *   - ayudante_asignado: string (correo del ayudante)
 *   - puntos: string[] (lista de IDs de puntos)
 *   - estado: string ("Pendiente", "En curso", "Finalizada")
 */
const RutasService = (() => {
    const API_BASE_URL = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/rutas'
        : '/rutas';

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
                console.error(`RutasService Error [${response.status}]:`, errorMsg);
                return { error: errorMsg };
            }
            return data;
        } catch (error) {
            console.error('RutasService Error de red:', error);
            return { error: `Error de conexión: ${error.message}. ¿Está el servidor ejecutándose?` };
        }
    }

    /**
     * Crea una nueva ruta de recolección.
     * @param {Object} ruta — Datos de la ruta (fecha, camion_asignado, chofer_asignado, ayudante_asignado, puntos, estado)
     * @returns {Promise<Object>} — { mensaje, ruta } o { error }
     */
    async function registrar(ruta) {
        return await _request('/registrar', {
            method: 'POST',
            body: JSON.stringify(ruta),
        });
    }

    /**
     * Obtiene todas las rutas registradas.
     * @returns {Promise<Array>} — Lista de rutas
     */
    async function obtenerTodas() {
        const resultado = await _request('/listar');
        if (resultado.error) {
            console.error('Error al obtener rutas:', resultado.error);
            return [];
        }
        return resultado.rutas || [];
    }

    /**
     * Obtiene una ruta por su ID.
     * @param {string} id — ID de la ruta
     * @returns {Promise<Object|null>} — La ruta o null
     */
    async function obtenerPorId(id) {
        const resultado = await _request(`/obtener/${encodeURIComponent(id)}`);
        if (resultado.error) return null;
        return resultado.ruta || null;
    }

    /**
     * Actualiza una ruta existente.
     * @param {string} id — ID de la ruta
     * @param {Object} datosActualizados — Campos a actualizar
     * @returns {Promise<Object>} — { mensaje } o { error }
     */
    async function actualizar(id, datosActualizados) {
        return await _request(`/actualizar/${encodeURIComponent(id)}`, {
            method: 'PUT',
            body: JSON.stringify(datosActualizados),
        });
    }

    /**
     * Elimina una ruta por ID.
     * @param {string} id — ID de la ruta
     * @returns {Promise<Object>} — { mensaje } o { error }
     */
    async function eliminar(id) {
        return await _request(`/eliminar/${encodeURIComponent(id)}`, {
            method: 'DELETE',
        });
    }

    return { registrar, obtenerTodas, obtenerPorId, actualizar, eliminar };
})();
