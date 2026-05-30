/**
 * puntos-mapa.js — Lógica de la pantalla de visualización del mapa (HU-04)
 *
 * Dependencias: puntos-service.js (debe cargarse antes)
 *
 * Funcionalidades:
 * - Carga puntos desde PuntosService
 * - Renderiza lista lateral con búsqueda y filtros
 * - Integra Google Maps con marcadores (si hay API key)
 * - Muestra placeholder si no hay API key configurada
 */

document.addEventListener('DOMContentLoaded', () => {
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

    // ========== OBTENER PUNTOS FILTRADOS ==========
    function obtenerPuntosFiltrados() {
        // TODO: Cuando el backend esté listo, PuntosService hará llamadas al API
        let puntos = PuntosService.obtenerTodos();

        // Filtro por estado
        if (filtroActual === 'activo') {
            puntos = puntos.filter(p => p.estado === 'activo');
        } else if (filtroActual === 'inactivo') {
            puntos = puntos.filter(p => p.estado === 'inactivo');
        }

        // Filtro por búsqueda
        if (busquedaActual.trim()) {
            const query = busquedaActual.toLowerCase().trim();
            puntos = puntos.filter(p =>
                p.nombre.toLowerCase().includes(query) ||
                p.direccion.toLowerCase().includes(query)
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
            const badgeClass = punto.estado === 'activo' ? 'badge-activo' : 'badge-inactivo';
            const estadoTexto = punto.estado === 'activo' ? 'Activo' : 'Inactivo';

            const materialesHtml = punto.tipoMaterial
                .map(m => `<span class="material-tag">${escapeHtml(m)}</span>`)
                .join('');

            html += `
                <div class="punto-card ${isSelected}" data-id="${punto.id}" data-lat="${punto.latitud}" data-lng="${punto.longitud}">
                    <div class="punto-card-header">
                        <h3 class="punto-card-nombre">${escapeHtml(punto.nombre)}</h3>
                        <span class="badge ${badgeClass}">${estadoTexto}</span>
                    </div>
                    <p class="punto-card-direccion">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                        </svg>
                        ${escapeHtml(punto.direccion)}
                    </p>
                    <div class="punto-card-materiales">
                        ${materialesHtml}
                    </div>
                    <div class="punto-card-horario">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        ${escapeHtml(punto.horario || 'Sin horario')}
                    </div>
                </div>
            `;
        });

        puntosListaEl.innerHTML = html;

        // Event listeners para las tarjetas
        document.querySelectorAll('.punto-card').forEach(card => {
            card.addEventListener('click', () => {
                const id = card.dataset.id;
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
     * Esta función es llamada como callback por la API de Google Maps
     * o manualmente si no hay API key.
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
            const marker = new google.maps.Marker({
                position: { lat: punto.latitud, lng: punto.longitud },
                map: map,
                title: punto.nombre,
                icon: {
                    url: punto.estado === 'activo'
                        ? 'https://maps.google.com/mapfiles/ms/icons/green-dot.png'
                        : 'https://maps.google.com/mapfiles/ms/icons/yellow-dot.png',
                    scaledSize: new google.maps.Size(40, 40)
                }
            });

            // Info Window al hacer clic en marcador
            marker.addListener('click', () => {
                const materialesHtml = punto.tipoMaterial
                    .map(m => `<span class="material-tag">${escapeHtml(m)}</span>`)
                    .join('');

                const content = `
                    <div class="gm-info-window">
                        <h3>${escapeHtml(punto.nombre)}</h3>
                        <p>${escapeHtml(punto.direccion)}</p>
                        <p>🕐 ${escapeHtml(punto.horario || 'Sin horario')}</p>
                        <div class="info-materiales">${materialesHtml}</div>
                    </div>
                `;

                infoWindow.setContent(content);
                infoWindow.open(map, marker);

                // Seleccionar en la lista lateral
                puntoSeleccionado = punto.id;
                document.querySelectorAll('.punto-card').forEach(c => {
                    c.classList.toggle('selected', c.dataset.id === punto.id);
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
            // Solo ajustar si hay más de un marcador
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
        }, 250); // Debounce de 250ms
    });

    // ========== UTILIDADES ==========
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // ========== INICIALIZACIÓN ==========
    renderizarLista();

    // Si no hay Google Maps cargado, mostrar mensaje
    if (typeof google === 'undefined' || !google.maps) {
        console.info('Google Maps API no cargada. Mostrando placeholder.');
        console.info('Para habilitar el mapa, configura GOOGLE_MAPS_API_KEY en puntos-mapa.html');
    }
});
