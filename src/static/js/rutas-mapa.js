document.addEventListener('DOMContentLoaded', () => {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    if (!currentUser) {
        window.location.href = 'login.html';
        return;
    }
    const userSpan = document.querySelector('.header-user span');
    if (userSpan) {
        userSpan.textContent = `${currentUser.nombre} ${currentUser.apellido || ''} (${currentUser.rol || 'Usuario'})`.trim();
    }

    const rutasListaEl = document.getElementById('rutas-lista');
    const listaCounter = document.getElementById('lista-counter');
    const toastContainer = document.getElementById('toast-container');
    
    // Modal
    const modalCrear = document.getElementById('modal-crear-ruta');
    const btnNuevaRuta = document.getElementById('btn-nueva-ruta');
    const btnCancelarRuta = document.getElementById('btn-cancelar-ruta');
    const formCrearRuta = document.getElementById('form-crear-ruta');
    const selectorPuntos = document.getElementById('selector-puntos');

    let todasLasRutas = [];
    let todosLosPuntos = [];
    let rutaSeleccionada = null;
    
    // Google Maps
    let map = null;
    let directionsService = null;
    let directionsRenderer = null;
    let markers = []; // para la ruta
    
    const CENTRO_MAPA = { lat: -35.0025173, lng: -71.2294064 };

    function mostrarToast(mensaje, tipo = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${tipo}`;
        toast.textContent = mensaje;
        toastContainer.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }

    window.initMap = function () {
        document.getElementById('mapa-placeholder').style.display = 'none';
        
        map = new google.maps.Map(document.getElementById('mapa-google'), {
            center: CENTRO_MAPA,
            zoom: 14,
            mapTypeControl: true,
            streetViewControl: false,
            fullscreenControl: true
        });
        
        directionsService = new google.maps.DirectionsService();
        directionsRenderer = new google.maps.DirectionsRenderer({ 
            map: map,
            suppressMarkers: true 
        });
        
        cargarDatos();
    };

    async function cargarDatos() {
        todosLosPuntos = await PuntosService.obtenerActivos();
        todasLasRutas = await RutasService.obtenerTodas();
        await cargarListas();
        renderizarListaRutas();
        renderizarOpcionesPuntos();
    }

    async function cargarListas() {
        try {
            const apiBase = window.CONFIG?.API_URL || (window.location.protocol === 'file:' ? 'http://127.0.0.1:8000' : '');
            
            // Camiones
            const resCam = await fetch(apiBase + '/camiones/obtener');
            if (resCam.ok) {
                const data = await resCam.json();
                const camiones = data.camiones || [];
                const datalistCamiones = document.getElementById('lista-camiones');
                if (datalistCamiones) {
                    datalistCamiones.innerHTML = camiones.map(c => `<option value="${c.patente}">`).join('');
                }
            }
            
            // Usuarios (choferes y ayudantes)
            const resUsr = await fetch(apiBase + '/usuarios/obtener');
            if (resUsr.ok) {
                const data = await resUsr.json();
                const usuarios = data.usuarios || [];
                const datalistUsuarios = document.getElementById('lista-usuarios');
                if (datalistUsuarios) {
                    datalistUsuarios.innerHTML = usuarios.map(u => `<option value="${u.correo}">${u.nombre} ${u.apellido} (${u.rol})</option>`).join('');
                }
            }
        } catch (error) {
            console.error('Error cargando listas:', error);
        }
    }

    function renderizarListaRutas() {
        listaCounter.textContent = `${todasLasRutas.length} rutas encontradas`;
        
        if (todasLasRutas.length === 0) {
            rutasListaEl.innerHTML = `<p style="text-align:center; color:#888;">No hay rutas registradas.</p>`;
            return;
        }

        let html = '';
        todasLasRutas.forEach(ruta => {
            const isSelected = rutaSeleccionada === ruta.id ? 'selected' : '';
            html += `
                <div class="punto-card ${isSelected}" data-id="${ruta.id}">
                    <div class="punto-card-header">
                        <h3 class="punto-card-nombre">Ruta: ${ruta.fecha}</h3>
                        <span class="badge ${ruta.estado === 'Pendiente' ? 'badge-inactivo' : 'badge-activo'}">${ruta.estado}</span>
                    </div>
                    <p class="punto-card-direccion">Camión: ${ruta.camion_asignado}</p>
                    <p class="punto-card-direccion">Puntos: ${ruta.puntos ? ruta.puntos.length : 0}</p>
                    
                    <div style="margin-top: 10px; display: flex; gap: 10px;">
                        <button class="btn-editar-ruta" data-id="${ruta.id}" style="padding:4px 8px; font-size:12px; cursor:pointer; background:#ffa000; color:white; border:none; border-radius:4px;">Editar</button>
                        <button class="btn-eliminar-ruta" data-id="${ruta.id}" style="padding:4px 8px; font-size:12px; cursor:pointer; background:#d32f2f; color:white; border:none; border-radius:4px;">Eliminar</button>
                    </div>
                </div>
            `;
        });
        
        rutasListaEl.innerHTML = html;

        document.querySelectorAll('.punto-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.classList.contains('btn-editar-ruta') || e.target.classList.contains('btn-eliminar-ruta')) {
                    return; // evitamos cargar el mapa al hacer clic en los botones
                }
                const id = card.dataset.id;
                rutaSeleccionada = id;
                document.querySelectorAll('.punto-card').forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');
                
                const ruta = todasLasRutas.find(r => r.id === id);
                mostrarRutaEnMapa(ruta);
            });
        });

        document.querySelectorAll('.btn-editar-ruta').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.target.dataset.id;
                const ruta = todasLasRutas.find(r => r.id === id);
                if (ruta) abirModalEditar(ruta);
            });
        });

        document.querySelectorAll('.btn-eliminar-ruta').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const id = e.target.dataset.id;
                if (confirm('¿Estás seguro de que deseas eliminar esta ruta?')) {
                    const res = await RutasService.eliminar(id);
                    if (res.error) {
                        mostrarToast(res.error, 'error');
                    } else {
                        mostrarToast('Ruta eliminada', 'success');
                        if (rutaSeleccionada === id) {
                            rutaSeleccionada = null;
                            directionsRenderer.setDirections({routes: []});
                        }
                        cargarDatos();
                    }
                }
            });
        });
    }

    function renderizarOpcionesPuntos() {
        const selectCanton = document.getElementById('ruta-canton');
        let htmlPuntos = '';
        let htmlCantones = '<option value="">Selecciona un Cantón...</option>';
        
        todosLosPuntos.forEach(p => {
            const isCanton = p.municipalidad.toLowerCase().includes('canton') || p.municipalidad.toLowerCase().includes('cantón');
            
            if (isCanton) {
                htmlCantones += `<option value="${p.id}" data-lat="${p.latitud}" data-lng="${p.longitud}">${p.municipalidad}</option>`;
            } else {
                htmlPuntos += `
                    <label style="display:flex; align-items:center; gap:8px; margin-bottom:6px; font-size:14px;">
                        <input type="checkbox" name="puntos_ruta" value="${p.id}" data-lat="${p.latitud}" data-lng="${p.longitud}">
                        <span><strong>${p.municipalidad}</strong> <br> <small style="color:#666;">Urgencia: ${p.urgencia} | Llenado: ${p.capacidad_ocupada}/${p.capacidad_maxima} kg</small></span>
                    </label>
                `;
            }
        });
        
        selectorPuntos.innerHTML = htmlPuntos;
        if (selectCanton) selectCanton.innerHTML = htmlCantones;
    }

    function limpiarMarcadoresRuta() {
        markers.forEach(m => m.setMap(null));
        markers = [];
    }

    function mostrarRutaEnMapa(ruta) {
        limpiarMarcadoresRuta();
        
        if (!ruta.polyline) {
            mostrarToast('Esta ruta no tiene información de trazado (polyline).', 'info');
            directionsRenderer.setDirections({routes: []}); // clear
            return;
        }
        
        if (ruta.puntos_ordenados && ruta.puntos_ordenados.length >= 2) {
            const waypoints = [];
            let origin = null;
            let dest = null;
            let indexParada = 1;
            
            ruta.puntos_ordenados.forEach((pid, index) => {
                const punto = todosLosPuntos.find(p => String(p.id) === String(pid));
                if (punto) {
                    const loc = { lat: punto.latitud, lng: punto.longitud };
                    
                    if (index === 0) {
                        origin = loc;
                        // Marcador especial para el Cantón (Inicio)
                        const markerCanton = new google.maps.Marker({
                            position: loc,
                            map: map,
                            title: `Cantón: ${punto.municipalidad}`,
                            icon: 'http://maps.google.com/mapfiles/kml/pal2/icon10.png', // Icono distinto (ej. home/edificio)
                            zIndex: 100
                        });
                        markers.push(markerCanton);
                    }
                    else if (index === ruta.puntos_ordenados.length - 1) {
                        dest = loc;
                    }
                    else {
                        waypoints.push({ location: loc, stopover: true });
                        // Marcadores enumerados para los puntos intermedios
                        const num = indexParada++;
                        const marker = new google.maps.Marker({
                            position: loc,
                            map: map,
                            title: `${num}. ${punto.municipalidad}`,
                            label: {
                                text: num.toString(),
                                color: 'white',
                                fontWeight: 'bold'
                            }
                        });
                        markers.push(marker);
                    }
                }
            });
            
            if (origin && dest) {
                directionsService.route({
                    origin: origin,
                    destination: dest,
                    waypoints: waypoints,
                    travelMode: google.maps.TravelMode.DRIVING
                }, (response, status) => {
                    if (status === 'OK') {
                        directionsRenderer.setDirections(response);
                    } else {
                        mostrarToast('Error al visualizar ruta: ' + status, 'error');
                    }
                });
            }
        }
    }

    // Modal events
    btnNuevaRuta.addEventListener('click', () => {
        document.getElementById('modal-title').textContent = 'Crear Nueva Ruta';
        document.getElementById('ruta-id').value = '';
        formCrearRuta.reset();
        modalCrear.style.display = 'flex';
    });
    
    function abirModalEditar(ruta) {
        document.getElementById('modal-title').textContent = 'Editar Ruta';
        document.getElementById('ruta-id').value = ruta.id;
        document.getElementById('ruta-fecha').value = ruta.fecha || '';
        document.getElementById('ruta-camion').value = ruta.camion_asignado || '';
        document.getElementById('ruta-chofer').value = ruta.chofer_asignado || '';
        document.getElementById('ruta-ayudante').value = ruta.ayudante_asignado || '';
        
        // Resetear checkboxes y canton
        document.getElementById('ruta-canton').value = '';
        Array.from(selectorPuntos.querySelectorAll('input[type="checkbox"]')).forEach(cb => cb.checked = false);

        if (ruta.puntos && ruta.puntos.length > 0) {
            // El primer punto suele ser el canton
            const posiblesCantones = Array.from(document.getElementById('ruta-canton').options).map(o => o.value);
            
            // Ver si el primer punto es un canton
            if (posiblesCantones.includes(ruta.puntos[0])) {
                document.getElementById('ruta-canton').value = ruta.puntos[0];
            }
            
            ruta.puntos.forEach(pid => {
                const cb = selectorPuntos.querySelector(`input[value="${pid}"]`);
                if (cb) cb.checked = true;
            });
        }
        
        modalCrear.style.display = 'flex';
    }

    btnCancelarRuta.addEventListener('click', () => {
        modalCrear.style.display = 'none';
    });

    formCrearRuta.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const selectCanton = document.getElementById('ruta-canton');
        const cantonSeleccionado = selectCanton.options[selectCanton.selectedIndex];
        
        if (!cantonSeleccionado || !cantonSeleccionado.value) {
            mostrarToast('Debes seleccionar un Cantón de inicio/fin.', 'error');
            return;
        }

        const seleccionados = Array.from(selectorPuntos.querySelectorAll('input:checked'));
        if (seleccionados.length < 1) {
            mostrarToast('Debes seleccionar al menos 1 punto para visitar.', 'error');
            return;
        }

        const origin = { lat: parseFloat(cantonSeleccionado.dataset.lat), lng: parseFloat(cantonSeleccionado.dataset.lng) };
        const destination = origin; // Inicia y termina en el mismo lugar
        
        const waypoints = seleccionados.map(inp => ({
            location: { lat: parseFloat(inp.dataset.lat), lng: parseFloat(inp.dataset.lng) },
            stopover: true
        }));
        
        const puntoIdsOriginal = seleccionados.map(inp => inp.value);
        const cantonId = cantonSeleccionado.value;

        directionsService.route({
            origin: origin,
            destination: destination,
            waypoints: waypoints,
            optimizeWaypoints: true,
            travelMode: google.maps.TravelMode.DRIVING
        }, async (response, status) => {
            if (status === 'OK') {
                const route = response.routes[0];
                const polyline = route.overview_polyline;
                
                // order is provided if optimizeWaypoints is true
                const order = route.waypoint_order; 
                let puntos_ordenados = [];
                
                puntos_ordenados.push(cantonId); // origin
                order.forEach(index => {
                    puntos_ordenados.push(puntoIdsOriginal[index]); // waypoints
                });
                puntos_ordenados.push(cantonId); // destination

                const nuevaRuta = {
                    fecha: document.getElementById('ruta-fecha').value,
                    camion_asignado: document.getElementById('ruta-camion').value,
                    chofer_asignado: document.getElementById('ruta-chofer').value,
                    ayudante_asignado: document.getElementById('ruta-ayudante').value,
                    puntos: [cantonId, ...puntoIdsOriginal], // todos los puntos asociados
                    estado: 'Pendiente',
                    polyline: polyline,
                    puntos_ordenados: puntos_ordenados
                };

                const idRutaEdit = document.getElementById('ruta-id').value;
                let res;
                if (idRutaEdit) {
                    // Actualizar
                    res = await RutasService.actualizar(idRutaEdit, nuevaRuta);
                } else {
                    // Crear
                    res = await RutasService.crear(nuevaRuta);
                }

                if (res.error) {
                    mostrarToast(res.error, 'error');
                } else {
                    mostrarToast(idRutaEdit ? 'Ruta actualizada exitosamente' : 'Ruta creada exitosamente', 'success');
                    modalCrear.style.display = 'none';
                    cargarDatos();
                }

            } else {
                mostrarToast('No se pudo generar la ruta con Google Maps: ' + status, 'error');
            }
        });
    });

    const btnSalir = document.getElementById('btn-salir');
    if (btnSalir) {
        btnSalir.addEventListener('click', () => {
            localStorage.removeItem('currentUser');
            window.location.href = 'login.html';
        });
    }
});
