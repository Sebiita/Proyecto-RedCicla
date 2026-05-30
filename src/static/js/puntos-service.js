/**
 * PuntosService — Capa de servicio abstracta para puntos de reciclaje.
 *
 * NOTA DE INTEGRACIÓN:
 * Este módulo usa localStorage como almacenamiento temporal.
 * Cuando el backend (FastAPI) esté listo, reemplazar las funciones
 * internas por llamadas fetch() al API. Ningún otro archivo
 * necesitará cambiar.
 *
 * Ejemplo futuro:
 *   async guardar(punto) {
 *     const res = await fetch(`${this.API_BASE_URL}/puntos`, {
 *       method: 'POST',
 *       headers: { 'Content-Type': 'application/json' },
 *       body: JSON.stringify(punto)
 *     });
 *     return res.json();
 *   }
 */

const PuntosService = (() => {
    // ========== CONFIGURACIÓN ==========
    const STORAGE_KEY = 'redcicla_puntos_reciclaje';

    // TODO: Cuando el backend esté listo, descomentar y usar esta URL base
    // const API_BASE_URL = 'http://127.0.0.1:8000/puntos';

    // ========== DATOS DE PRUEBA ==========
    const DATOS_PRUEBA = [
        {
            id: 'demo-001',
            nombre: 'Punto Verde Plaza de Armas',
            direccion: 'Plaza de Armas de Curicó, calle Merced',
            latitud: -34.9827,
            longitud: -71.2353,
            tipoMaterial: ['plástico', 'vidrio', 'papel'],
            horario: '08:00 - 18:00',
            estado: 'activo',
            fechaCreacion: '2026-05-28T10:00:00'
        },
        {
            id: 'demo-002',
            nombre: 'EcoPunto Campus Curicó UTalca',
            direccion: 'Av. Lircay s/n, Campus Curicó',
            latitud: -35.0025,
            longitud: -71.2294,
            tipoMaterial: ['plástico', 'papel', 'cartón', 'electrónicos'],
            horario: '07:00 - 22:00',
            estado: 'activo',
            fechaCreacion: '2026-05-25T09:00:00'
        },
        {
            id: 'demo-003',
            nombre: 'Contenedor Reciclaje Supermercado',
            direccion: 'Av. Manso de Velasco 301, Curicó',
            latitud: -34.9870,
            longitud: -71.2400,
            tipoMaterial: ['vidrio', 'latas'],
            horario: '09:00 - 21:00',
            estado: 'activo',
            fechaCreacion: '2026-05-20T14:00:00'
        },
        {
            id: 'demo-004',
            nombre: 'Punto Limpio Municipal',
            direccion: 'Camino a Zapallar km 2, Curicó',
            latitud: -34.9750,
            longitud: -71.2200,
            tipoMaterial: ['plástico', 'vidrio', 'papel', 'cartón', 'latas', 'electrónicos'],
            horario: '08:00 - 17:00',
            estado: 'inactivo',
            fechaCreacion: '2026-05-15T11:00:00'
        }
    ];

    // ========== FUNCIONES INTERNAS DE ALMACENAMIENTO ==========

    /**
     * Lee todos los puntos del almacenamiento.
     * TODO: Reemplazar por GET /api/puntos cuando el backend esté listo.
     */
    function _leerStorage() {
        try {
            const datos = localStorage.getItem(STORAGE_KEY);
            return datos ? JSON.parse(datos) : null;
        } catch (e) {
            console.error('Error al leer localStorage:', e);
            return null;
        }
    }

    /**
     * Escribe los puntos al almacenamiento.
     * TODO: Este método desaparecerá cuando se use el backend.
     */
    function _escribirStorage(puntos) {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(puntos));
        } catch (e) {
            console.error('Error al escribir localStorage:', e);
        }
    }

    /**
     * Inicializa los datos de prueba si no existen.
     */
    function _inicializarDatosPrueba() {
        if (_leerStorage() === null) {
            _escribirStorage(DATOS_PRUEBA);
            console.log('PuntosService: Datos de prueba cargados.');
        }
    }

    // ========== GENERAR ID ÚNICO ==========
    function _generarId() {
        return 'pt-' + Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 8);
    }

    // ========== API PÚBLICA ==========

    /**
     * Guarda un nuevo punto de reciclaje.
     * @param {Object} punto — Datos del punto (sin id ni fechaCreacion)
     * @returns {Object} — El punto guardado con id y fechaCreacion asignados
     *
     * TODO: Reemplazar por POST /api/puntos
     */
    function guardar(punto) {
        const puntos = _leerStorage() || [];
        const nuevoPunto = {
            id: _generarId(),
            ...punto,
            fechaCreacion: new Date().toISOString()
        };
        puntos.push(nuevoPunto);
        _escribirStorage(puntos);
        return nuevoPunto;
    }

    /**
     * Obtiene todos los puntos de reciclaje.
     * @returns {Array} — Lista de todos los puntos
     *
     * TODO: Reemplazar por GET /api/puntos
     */
    function obtenerTodos() {
        return _leerStorage() || [];
    }

    /**
     * Obtiene un punto por su ID.
     * @param {string} id — ID del punto
     * @returns {Object|null} — El punto o null si no existe
     *
     * TODO: Reemplazar por GET /api/puntos/{id}
     */
    function obtenerPorId(id) {
        const puntos = _leerStorage() || [];
        return puntos.find(p => p.id === id) || null;
    }

    /**
     * Actualiza un punto existente.
     * @param {string} id — ID del punto a actualizar
     * @param {Object} datosActualizados — Campos a actualizar
     * @returns {Object|null} — El punto actualizado o null si no existe
     *
     * TODO: Reemplazar por PUT /api/puntos/{id}
     */
    function actualizar(id, datosActualizados) {
        const puntos = _leerStorage() || [];
        const indice = puntos.findIndex(p => p.id === id);
        if (indice === -1) return null;

        puntos[indice] = { ...puntos[indice], ...datosActualizados };
        _escribirStorage(puntos);
        return puntos[indice];
    }

    /**
     * Elimina un punto por su ID.
     * @param {string} id — ID del punto a eliminar
     * @returns {boolean} — true si se eliminó, false si no existía
     *
     * TODO: Reemplazar por DELETE /api/puntos/{id}
     */
    function eliminar(id) {
        const puntos = _leerStorage() || [];
        const nuevaLista = puntos.filter(p => p.id !== id);
        if (nuevaLista.length === puntos.length) return false;

        _escribirStorage(nuevaLista);
        return true;
    }

    /**
     * Obtiene solo los puntos activos.
     * @returns {Array} — Lista de puntos con estado "activo"
     */
    function obtenerActivos() {
        return obtenerTodos().filter(p => p.estado === 'activo');
    }

    // ========== INICIALIZACIÓN ==========
    _inicializarDatosPrueba();

    // ========== EXPOSICIÓN DEL MÓDULO ==========
    return {
        guardar,
        obtenerTodos,
        obtenerPorId,
        actualizar,
        eliminar,
        obtenerActivos
    };
})();
