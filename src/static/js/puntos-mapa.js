/**
 * puntos-mapa.js — Lógica de la pantalla de visualización del mapa (HU-04)
 *
 * Dependencias: puntos-service.js (debe cargarse antes)
 *
 * Conectado al backend FastAPI:
 *   GET /puntos/obtener → Listar todos los puntos
 *
 * Modelo de datos del backend:
 *   { id, municipalidad, latitud, longitud, estado, urgencia, capacidad_maxima, capacidad_ocupada }
 */

document.addEventListener('DOMContentLoaded', () => {
    // ========== USUARIO AUTENTICADO ==========
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    if (!currentUser) {
        window.location.href = 'login.html';
        return;
    }
    const userSpan = document.querySelector('.header-user span');
    if (userSpan) {
        userSpan.textContent = `${currentUser.nombre} ${currentUser.apellido || ''} (${currentUser.rol || 'Usuario'})`.trim();
    }

    // ========== ELEMENTOS DOM ==========
    const puntosListaEl = document.getElementById('puntos-lista');
    const listaCounter = document.getElementById('lista-counter');
    const buscarInput = document.getElementById('buscar-punto');
    const toastContainer = document.getElementById('toast-container');
    const mapaPlaceholder = document.getElementById('mapa-placeholder');

    // Filtros
    const filtroTodos = document.getElementById('filtro-todos');
    const filtroActivos = document.getElementById('filtro-activos');
    const filtroInactivos = document.getElementById('filtro-inactivos');
    const filtros = [filtroTodos, filtroActivos, filtroInactivos];

    // Estado
    let filtroActual = 'todos';
    let busquedaActual = '';
    let puntoSeleccionado = null;
    let todosLosPuntos = []; // Cache de puntos cargados del backend

    // Google Maps
    let map = null;
    let markers = [];
    let infoWindow = null;

    // Centro: Curicó, Chile (Campus Universidad de Talca)
    const CENTRO_MAPA = { lat: -35.0025173, lng: -71.2294064 };
    const ZOOM_INICIAL = 14;
    const ZOOM_PUNTO = 17;

    // ========== TOAST ==========
    function mostrarToast(mensaje, tipo = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${tipo}`;
        toast.textContent = mensaje;
        toastContainer.appendChild(toast);
        setTimeout(() => {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 3000);
    }

    // ========== CARGAR PUNTOS DESDE BACKEND ==========
    async function cargarPuntos() {
        todosLosPuntos = await PuntosService.obtenerTodos();
    }

    // ========== OBTENER PUNTOS FILTRADOS ==========
    function obtenerPuntosFiltrados() {
        let puntos = [...todosLosPuntos];

        // Filtro por estado (el backend usa "Activo", "Inactivo", "Mantencion")
        if (filtroActual === 'activo') {
            puntos = puntos.filter(p => p.estado === 'Activo');
        } else if (filtroActual === 'inactivo') {
            puntos = puntos.filter(p => p.estado !== 'Activo');
        }

        // Filtro por búsqueda (buscar en municipalidad)
        if (busquedaActual.trim()) {
            const query = busquedaActual.toLowerCase().trim();
            puntos = puntos.filter(p =>
                p.municipalidad.toLowerCase().includes(query)
            );
        }

        return puntos;
    }

    // ========== RENDERIZAR LISTA DE PUNTOS ==========
    function renderizarLista() {
        const puntos = obtenerPuntosFiltrados();

        // Actualizar contador
        listaCounter.textContent = `${puntos.length} punto${puntos.length !== 1 ? 's' : ''} encontrado${puntos.length !== 1 ? 's' : ''}`;

        // Si no hay puntos
        if (puntos.length === 0) {
            puntosListaEl.innerHTML = `
                <div class="lista-empty">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                    <p>${busquedaActual ? 'No se encontraron puntos con esa búsqueda.' : 'No hay puntos de reciclaje registrados.'}</p>
                </div>
            `;
            return;
        }

        // Renderizar tarjetas
        let html = '';
        puntos.forEach(punto => {
            const isSelected = puntoSeleccionado === punto.id ? 'selected' : '';

            // Badge de estado
            let badgeClass = 'badge-activo';
            if (punto.estado !== 'Activo') badgeClass = 'badge-inactivo';

            // Porcentaje de capacidad
            const porcCapacidad = punto.capacidad_maxima > 0
                ? Math.round((punto.capacidad_ocupada / punto.capacidad_maxima) * 100)
                : 0;

            // Badge de urgencia
            let urgenciaIcon = '';
            switch (punto.urgencia) {
                case 'Alta': urgenciaIcon = '⚠️'; break;
                case 'Crítica': urgenciaIcon = '🔴'; break;
                default: urgenciaIcon = '';
            }

            html += `
                <div class="punto-card ${isSelected}" data-id="${punto.id}" data-lat="${punto.latitud}" data-lng="${punto.longitud}">
                    <div class="punto-card-header">
                        <h3 class="punto-card-nombre">${urgenciaIcon} ${escapeHtml(punto.municipalidad)}</h3>
                        <span class="badge ${badgeClass}">${escapeHtml(punto.estado)}</span>
                    </div>
                    <p class="punto-card-direccion">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                        </svg>
                        ${punto.latitud.toFixed(4)}, ${punto.longitud.toFixed(4)}
                    </p>
                    <div class="punto-card-materiales">
                        <span class="material-tag">Urgencia: ${escapeHtml(punto.urgencia)}</span>
                        <span class="material-tag">${porcCapacidad}% lleno</span>
                    </div>
                    <div class="punto-card-horario">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
                        </svg>
                        ${punto.capacidad_ocupada}/${punto.capacidad_maxima} kg
                    </div>
                </div>
            `;
        });

        puntosListaEl.innerHTML = html;

        // Event listeners para las tarjetas
        document.querySelectorAll('.punto-card').forEach(card => {
            card.addEventListener('click', () => {
                const id = parseInt(card.dataset.id);
                const lat = parseFloat(card.dataset.lat);
                const lng = parseFloat(card.dataset.lng);

                // Seleccionar visualmente
                puntoSeleccionado = id;
                document.querySelectorAll('.punto-card').forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');

                // Centrar mapa en el punto
                centrarMapa(lat, lng, id);
            });
        });

        // Actualizar marcadores del mapa
        actualizarMarcadores(puntos);
    }

    // ========== GOOGLE MAPS ==========

    /**
     * Inicializa Google Maps.
     * Esta función es llamada como callback por la API de Google Maps.
     */
    window.initMap = function () {
        // Ocultar placeholder
        if (mapaPlaceholder) {
            mapaPlaceholder.style.display = 'none';
        }

        map = new google.maps.Map(document.getElementById('mapa-google'), {
            center: CENTRO_MAPA,
            zoom: ZOOM_INICIAL,
            mapTypeControl: true,
            streetViewControl: false,
            fullscreenControl: true,
            zoomControl: true,
            styles: [
                {
                    featureType: 'poi',
                    elementType: 'labels',
                    stylers: [{ visibility: 'off' }]
                }
            ]
        });

        infoWindow = new google.maps.InfoWindow();

        // Renderizar marcadores iniciales
        const puntos = obtenerPuntosFiltrados();
        actualizarMarcadores(puntos);

        mostrarToast('Mapa cargado correctamente.', 'success');
    };

    /**
     * Actualiza los marcadores en el mapa.
     */
    function actualizarMarcadores(puntos) {
        if (!map) return;

        // Limpiar marcadores existentes
        markers.forEach(m => m.setMap(null));
        markers = [];

        puntos.forEach(punto => {
            // Color del marcador según estado y urgencia
            let iconUrl = 'https://maps.google.com/mapfiles/ms/icons/green-dot.png';
            if (punto.estado !== 'Activo') {
                iconUrl = 'https://maps.google.com/mapfiles/ms/icons/yellow-dot.png';
            }
            if (punto.urgencia === 'Alta' || punto.urgencia === 'Crítica') {
                iconUrl = 'https://maps.google.com/mapfiles/ms/icons/red-dot.png';
            }

            const marker = new google.maps.Marker({
                position: { lat: punto.latitud, lng: punto.longitud },
                map: map,
                title: punto.municipalidad,
                icon: {
                    url: iconUrl,
                    scaledSize: new google.maps.Size(40, 40)
                }
            });

            // Porcentaje de capacidad
            const porcCapacidad = punto.capacidad_maxima > 0
                ? Math.round((punto.capacidad_ocupada / punto.capacidad_maxima) * 100)
                : 0;

            // Info Window al hacer clic en marcador
            marker.addListener('click', () => {
                const content = `
                    <div class="gm-info-window">
                        <h3>${escapeHtml(punto.municipalidad)}</h3>
                        <p>📍 ${punto.latitud.toFixed(4)}, ${punto.longitud.toFixed(4)}</p>
                        <p>📊 Estado: ${escapeHtml(punto.estado)} | Urgencia: ${escapeHtml(punto.urgencia)}</p>
                        <p>📦 Capacidad: ${punto.capacidad_ocupada}/${punto.capacidad_maxima} kg (${porcCapacidad}%)</p>
                    </div>
                `;

                infoWindow.setContent(content);
                infoWindow.open(map, marker);

                // Seleccionar en la lista lateral
                puntoSeleccionado = punto.id;
                document.querySelectorAll('.punto-card').forEach(c => {
                    c.classList.toggle('selected', parseInt(c.dataset.id) === punto.id);
                });

                // Scroll al punto en la lista
                const cardEl = document.querySelector(`.punto-card[data-id="${punto.id}"]`);
                if (cardEl) {
                    cardEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                }
            });

            marker._puntoId = punto.id;
            markers.push(marker);
        });

        // Ajustar bounds si hay marcadores
        if (markers.length > 0) {
            const bounds = new google.maps.LatLngBounds();
            markers.forEach(m => bounds.extend(m.getPosition()));
            if (markers.length > 1) {
                map.fitBounds(bounds, { padding: 50 });
            }
        }
    }

    /**
     * Centra el mapa en un punto específico.
     */
    function centrarMapa(lat, lng, puntoId) {
        if (!map) {
            mostrarToast('Mapa no disponible. Configura la API key de Google Maps.', 'info');
            return;
        }

        map.panTo({ lat, lng });
        map.setZoom(ZOOM_PUNTO);

        // Abrir info window del marcador correspondiente
        const marker = markers.find(m => m._puntoId === puntoId);
        if (marker) {
            google.maps.event.trigger(marker, 'click');
        }
    }

    // ========== FILTROS ==========
    filtros.forEach(btn => {
        btn.addEventListener('click', () => {
            filtros.forEach(f => f.classList.remove('active'));
            btn.classList.add('active');
            filtroActual = btn.dataset.filtro;
            puntoSeleccionado = null;
            renderizarLista();
        });
    });

    // ========== BÚSQUEDA ==========
    let buscarTimeout = null;
    buscarInput.addEventListener('input', () => {
        clearTimeout(buscarTimeout);
        buscarTimeout = setTimeout(() => {
            busquedaActual = buscarInput.value;
            puntoSeleccionado = null;
            renderizarLista();
        }, 250);
    });

    // ========== SALIR (CERRAR SESIÓN) ==========
    const btnSalir = document.getElementById('btn-salir');
    if (btnSalir) {
        btnSalir.addEventListener('click', () => {
            localStorage.removeItem('currentUser');
            mostrarToast('Cerrando sesión...', 'info');
            setTimeout(() => {
                window.location.href = 'landing.html';
            }, 800);
        });
    }

    // ========== UTILIDADES ==========
    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const div = document.createElement('div');
        div.textContent = String(text);
        return div.innerHTML;
    }

    // ========== INICIALIZACIÓN ==========
    async function init() {
        await cargarPuntos();
        renderizarLista();

        // Si no hay Google Maps cargado, mostrar mensaje
        if (typeof google === 'undefined' || !google.maps) {
            console.info('Google Maps API no cargada. Mostrando placeholder.');
            console.info('Para habilitar el mapa, configura GOOGLE_MAPS_API_KEY en puntos-mapa.html');
        }
    }

    init();
});
