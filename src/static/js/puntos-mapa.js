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

        // Creación de puntos desactivada (click en marcadores para editar existentes)
        // habilitarCreacionClick();

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
                // Abrir info window con vista y opciones de editar
                abrirEditorPunto(punto, marker, false);
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

    // ========== EDICIÓN / CREACIÓN DE PUNTOS ==========

    /**
     * Abre un editor dentro de un InfoWindow. Si isNew=true, el punto aún no existe en el backend.
     */
    function abrirEditorPunto(punto, marker, isNew = false) {
        const container = document.createElement('div');
        container.className = 'gm-editor';
        container.style.cssText = `
            width: 320px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif;
            font-size: 13px;
        `;

        container.innerHTML = `
            <div style="padding: 12px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <!-- Header -->
                <div style="margin-bottom: 14px; padding-bottom: 10px; border-bottom: 1px solid #e5e7eb;">
                    <h3 style="margin: 0 0 4px 0; font-size: 16px; font-weight: 600; color: #1f2937;">
                        ${isNew ? '➕ Nuevo Punto' : '📍 Editar Punto'}
                    </h3>
                    <p style="margin: 0; font-size: 12px; color: #6b7280;">
                        ${isNew ? 'Completa los datos para crear' : 'Modifica los datos y guarda'}
                    </p>
                </div>

                <!-- Formulario -->
                <div style="display: flex; flex-direction: column; gap: 10px;">
                    <!-- Nombre -->
                    <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                        <span style="font-weight: 500; font-size: 12px;">📛 Nombre</span>
                        <input id="gm-municipalidad" type="text" placeholder="Ej: Centro de Reciclaje" 
                            value="${escapeHtml(punto.municipalidad || '')}"
                            style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 13px;">
                    </label>

                    <!-- Coordenadas -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                        <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                            <span style="font-weight: 500; font-size: 12px;">🧭 Lat</span>
                            <input id="gm-lat" type="number" step="0.000001" value="${punto.latitud || ''}"
                                style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 12px;">
                        </label>
                        <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                            <span style="font-weight: 500; font-size: 12px;">🧭 Lng</span>
                            <input id="gm-lng" type="number" step="0.000001" value="${punto.longitud || ''}"
                                style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 12px;">
                        </label>
                    </div>

                    <!-- Estado -->
                    <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                        <span style="font-weight: 500; font-size: 12px;">✅ Estado</span>
                        <select id="gm-estado" style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 13px; cursor: pointer;">
                            <option value="Activo">Activo</option>
                            <option value="Inactivo">Inactivo</option>
                            <option value="Mantencion">Mantencion</option>
                        </select>
                    </label>

                    <!-- Urgencia -->
                    <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                        <span style="font-weight: 500; font-size: 12px;">⚠️ Urgencia</span>
                        <select id="gm-urgencia" style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 13px; cursor: pointer;">
                            <option value="Baja">Baja</option>
                            <option value="Normal">Normal</option>
                            <option value="Alta">Alta</option>
                            <option value="Crítica">Crítica</option>
                        </select>
                    </label>

                    <!-- Capacidad -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                        <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                            <span style="font-weight: 500; font-size: 12px;">📦 Máx (kg)</span>
                            <input id="gm-cap-max" type="number" step="0.1" value="${punto.capacidad_maxima || 0}"
                                style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 12px;">
                        </label>
                        <label style="display: flex; flex-direction: column; gap: 4px; color: #374151;">
                            <span style="font-weight: 500; font-size: 12px;">📊 Actual (kg)</span>
                            <input id="gm-cap-act" type="number" step="0.1" value="${punto.capacidad_ocupada || 0}"
                                style="padding: 6px 8px; border: 1px solid #d1d5db; border-radius: 4px; font-size: 12px;">
                        </label>
                    </div>
                </div>

                <!-- Botones -->
                <div style="margin-top: 14px; padding-top: 10px; border-top: 1px solid #e5e7eb; display: flex; gap: 8px;">
                    <button id="gm-save" style="flex: 1; padding: 8px 12px; background: #10b981; color: white; border: none; border-radius: 4px; font-weight: 500; cursor: pointer; font-size: 12px; transition: background 0.2s;">
                        💾 Guardar
                    </button>
                    ${isNew ? `
                        <button id="gm-cancel" style="flex: 1; padding: 8px 12px; background: #9ca3af; color: white; border: none; border-radius: 4px; font-weight: 500; cursor: pointer; font-size: 12px; transition: background 0.2s;">
                            ❌ Cancelar
                        </button>
                    ` : `
                        <button id="gm-delete" style="flex: 1; padding: 8px 12px; background: #ef4444; color: white; border: none; border-radius: 4px; font-weight: 500; cursor: pointer; font-size: 12px; transition: background 0.2s;">
                            🗑️ Eliminar
                        </button>
                    `}
                </div>
            </div>
        `;

        // Ajustar selects a los valores actuales
        setTimeout(() => {
            const selEstado = container.querySelector('#gm-estado');
            const selUrg = container.querySelector('#gm-urgencia');
            if (selEstado && punto.estado) selEstado.value = punto.estado;
            if (selUrg && punto.urgencia) selUrg.value = punto.urgencia;

            // Habilitar arrastre del marcador para actualizar coords
            marker.setDraggable(true);
            marker.addListener('dragend', () => {
                const pos = marker.getPosition();
                container.querySelector('#gm-lat').value = pos.lat().toFixed(6);
                container.querySelector('#gm-lng').value = pos.lng().toFixed(6);
            });

            // Botones con efectos hover
            const btnSave = container.querySelector('#gm-save');
            const btnDelete = container.querySelector('#gm-delete');
            const btnCancel = container.querySelector('#gm-cancel');

            if (btnSave) {
                btnSave.addEventListener('mouseenter', () => btnSave.style.background = '#059669');
                btnSave.addEventListener('mouseleave', () => btnSave.style.background = '#10b981');
            }
            if (btnDelete) {
                btnDelete.addEventListener('mouseenter', () => btnDelete.style.background = '#dc2626');
                btnDelete.addEventListener('mouseleave', () => btnDelete.style.background = '#ef4444');
            }
            if (btnCancel) {
                btnCancel.addEventListener('mouseenter', () => btnCancel.style.background = '#6b7280');
                btnCancel.addEventListener('mouseleave', () => btnCancel.style.background = '#9ca3af');
            }

            // Guardar
            container.querySelector('#gm-save').addEventListener('click', async () => {
                const datos = {
                    municipalidad: container.querySelector('#gm-municipalidad').value.trim(),
                    latitud: parseFloat(container.querySelector('#gm-lat').value),
                    longitud: parseFloat(container.querySelector('#gm-lng').value),
                    estado: container.querySelector('#gm-estado').value,
                    urgencia: container.querySelector('#gm-urgencia').value,
                    capacidad_maxima: parseFloat(container.querySelector('#gm-cap-max').value) || 0,
                    capacidad_ocupada: parseFloat(container.querySelector('#gm-cap-act').value) || 0,
                };

                if (isNew) {
                    const res = await PuntosService.guardar(datos);
                    if (res.error) {
                        mostrarToast(res.error, 'error');
                    } else {
                        mostrarToast(res.mensaje || 'Punto creado', 'success');
                        await cargarPuntos();
                        renderizarLista();
                    }
                } else {
                    const res = await PuntosService.actualizar(punto.id, datos);
                    if (res.error) {
                        mostrarToast(res.error, 'error');
                    } else {
                        mostrarToast(res.mensaje || 'Punto actualizado', 'success');
                        await cargarPuntos();
                        renderizarLista();
                    }
                }
                infoWindow.close();
            });

            // Eliminar o cancelar
            if (isNew) {
                container.querySelector('#gm-cancel').addEventListener('click', () => {
                    marker.setMap(null);
                    infoWindow.close();
                });
            } else {
                container.querySelector('#gm-delete').addEventListener('click', async () => {
                    if (!confirm('Eliminar punto? Esta acción no se puede deshacer.')) return;
                    const res = await PuntosService.eliminar(punto.id);
                    if (res.error) {
                        mostrarToast(res.error, 'error');
                    } else {
                        mostrarToast(res.mensaje || 'Punto eliminado', 'success');
                        await cargarPuntos();
                        renderizarLista();
                    }
                    infoWindow.close();
                });
            }
        }, 50);

        infoWindow.setContent(container);
        infoWindow.open(map, marker);
    }

    // Crear marcador temporal al hacer click en el mapa para registrar un nuevo punto
    function habilitarCreacionClick() {
        if (!map) return;
        map.addListener('click', (e) => {
            const pos = e.latLng;
            const puntoTemp = {
                municipalidad: '',
                latitud: parseFloat(pos.lat().toFixed(6)),
                longitud: parseFloat(pos.lng().toFixed(6)),
                estado: 'Activo',
                urgencia: 'Normal',
                capacidad_maxima: 0,
                capacidad_ocupada: 0,
            };

            const marker = new google.maps.Marker({
                position: pos,
                map: map,
                draggable: true,
                title: 'Nuevo punto (arrastra para ajustar)',
                icon: {
                    url: 'https://maps.google.com/mapfiles/ms/icons/blue-dot.png',
                    scaledSize: new google.maps.Size(40, 40)
                }
            });

            abrirEditorPunto(puntoTemp, marker, true);
        });
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
