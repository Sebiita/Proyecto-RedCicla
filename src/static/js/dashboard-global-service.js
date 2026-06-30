/**
 * DashboardService — Capa de servicio para el Dashboard Global.
 *
 * Conecta el frontend con el endpoint FastAPI:
 *   GET /dashboard/hoy
 *
 * Respuesta esperada:
 * {
 *   fecha: "YYYY-MM-DD",
 *   rutas: [
 *     {
 *       id, camion_asignado, chofer_asignado, ayudante_asignado, estado,
 *       total_puntos, puntos_completados, porcentaje_avance,
 *       puntos_estado: [
 *         { punto_id, estado_recoleccion, municipalidad, urgencia,
 *           capacidad_maxima, capacidad_ocupada, kilos_recogidos, timestamp_ficha }
 *       ]
 *     }
 *   ],
 *   resumen: {
 *     total_rutas, total_puntos, total_completados, total_en_espera, porcentaje_global
 *   }
 * }
 */

const DashboardService = (() => {
    const API_BASE = window.location.protocol === 'file:'
        ? 'http://127.0.0.1:8000/dashboard'
        : '/dashboard';

    /**
     * Petición interna con manejo de errores.
     */
    async function _request(endpoint, opciones = {}) {
        const url = `${API_BASE}${endpoint}`;
        try {
            const res = await fetch(url, {
                headers: { 'Content-Type': 'application/json' },
                ...opciones,
            });
            const data = await res.json();
            if (!res.ok) {
                const msg = data.detail || data.error || `Error HTTP ${res.status}`;
                return { error: msg };
            }
            return data;
        } catch (err) {
            return { error: `Error de conexión: ${err.message}` };
        }
    }

    /**
     * Obtiene el dashboard del día actual.
     * @returns {Promise<Object>} { fecha, rutas, resumen } | { error }
     */
    async function obtenerHoy() {
        return await _request('/hoy');
    }

    return { obtenerHoy };
})();
