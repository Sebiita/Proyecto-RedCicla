/**
 * rutas-recoleccion.js
 * Lógica de UI para la página de Rutas de Recolección.
 * Gestiona tabs, formulario de asignación, tablas, modales y toasts.
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

    // ========== TABS ==========
    const tabBtns = document.querySelectorAll('.rutas-tab-btn');
    const tabContents = document.querySelectorAll('.rutas-tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const target = btn.dataset.tab;
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById(`tab-${target}`).classList.add('active');
        });
    });

    // ========== TOAST ==========
    function showToast(message, type = 'success') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3200);
    }

    // ========== VALIDACIÓN HELPERS ==========
    function showError(inputId, errorId) {
        const input = document.getElementById(inputId);
        const error = document.getElementById(errorId);
        if (input) input.classList.add('error');
        if (error) error.classList.add('visible');
    }

    function clearError(inputId, errorId) {
        const input = document.getElementById(inputId);
        const error = document.getElementById(errorId);
        if (input) input.classList.remove('error');
        if (error) error.classList.remove('visible');
    }

    function clearAllFormErrors() {
        document.querySelectorAll('#form-ruta .error').forEach(el => el.classList.remove('error'));
        document.querySelectorAll('#form-ruta .error-msg').forEach(el => el.classList.remove('visible'));
        const puntosSelector = document.getElementById('puntos-selector');
        if (puntosSelector) puntosSelector.classList.remove('error');
    }

    // ========== DATOS PARA SELECTS ==========
    // Almacén local para mapear IDs a nombres
    let puntosMap = {};

    async function cargarSelectCamiones() {
        const select = document.getElementById('ruta-camion');
        try {
            const camiones = await CamionesService.obtenerTodos();
            const operativos = camiones.filter(c => c.estado_mantencion === 'Operativo');

            if (operativos.length === 0) {
                select.innerHTML = '<option value="" disabled selected>No hay camiones operativos</option>';
            } else {
                select.innerHTML = '<option value="" disabled selected>Seleccione un camión</option>';
                operativos.forEach(c => {
                    const opt = document.createElement('option');
                    opt.value = c.patente;
                    opt.textContent = `${c.patente} — ${c.capacidad} kg`;
                    select.appendChild(opt);
                });
            }
        } catch (err) {
            select.innerHTML = '<option value="" disabled selected>Error al cargar camiones</option>';
        }
    }

    async function cargarSelectChoferes() {
        const select = document.getElementById('ruta-chofer');
        try {
            const todos = await PersonalService.obtenerTodos();
            const choferes = todos.filter(u => u.rol === 'Chofer' && u.estado === 'Activo');

            if (choferes.length === 0) {
                select.innerHTML = '<option value="" disabled selected>No hay choferes activos</option>';
            } else {
                select.innerHTML = '<option value="" disabled selected>Seleccione un chofer</option>';
                choferes.forEach(c => {
                    const opt = document.createElement('option');
                    opt.value = c.correo;
                    opt.textContent = `${c.nombre} ${c.apellido}`;
                    select.appendChild(opt);
                });
            }
        } catch (err) {
            select.innerHTML = '<option value="" disabled selected>Error al cargar choferes</option>';
        }
    }

    async function cargarSelectAyudantes() {
        const select = document.getElementById('ruta-ayudante');
        try {
            const todos = await PersonalService.obtenerTodos();
            const ayudantes = todos.filter(u => u.rol === 'Ayudante' && u.estado === 'Activo');

            if (ayudantes.length === 0) {
                select.innerHTML = '<option value="" disabled selected>No hay ayudantes activos</option>';
            } else {
                select.innerHTML = '<option value="" disabled selected>Seleccione un ayudante</option>';
                ayudantes.forEach(a => {
                    const opt = document.createElement('option');
                    opt.value = a.correo;
                    opt.textContent = `${a.nombre} ${a.apellido}`;
                    select.appendChild(opt);
                });
            }
        } catch (err) {
            select.innerHTML = '<option value="" disabled selected>Error al cargar ayudantes</option>';
        }
    }

    async function cargarPuntosCheckboxes() {
        const container = document.getElementById('puntos-selector');
        const counter = document.getElementById('puntos-counter');
        try {
            const puntos = await PuntosService.obtenerActivos();

            if (puntos.length === 0) {
                container.innerHTML = '<div class="puntos-selector-empty">No hay puntos activos disponibles</div>';
                return;
            }

            // Guardar mapa de puntos para uso en la tabla
            puntos.forEach(p => {
                puntosMap[p.id] = p.municipalidad || `Punto ${p.id}`;
            });

            const urgenciaBadge = (urgencia) => {
                switch (urgencia) {
                    case 'Baja': return 'punto-urgencia urgencia-baja';
                    case 'Normal': return 'punto-urgencia urgencia-normal';
                    case 'Alta': return 'punto-urgencia urgencia-alta';
                    case 'Crítica': return 'punto-urgencia urgencia-critica';
                    default: return 'punto-urgencia urgencia-normal';
                }
            };

            container.innerHTML = puntos.map(p => `
                <div class="punto-checkbox-item">
                    <input type="checkbox" id="punto-${p.id}" value="${p.id}" name="puntos">
                    <label for="punto-${p.id}">${p.municipalidad || 'Sin nombre'}</label>
                    <span class="${urgenciaBadge(p.urgencia)}">${p.urgencia || 'Normal'}</span>
                </div>
            `).join('');

            // Actualizar contador al cambiar checkboxes
            container.querySelectorAll('input[type="checkbox"]').forEach(cb => {
                cb.addEventListener('change', () => {
                    const seleccionados = container.querySelectorAll('input[type="checkbox"]:checked').length;
                    counter.textContent = `${seleccionados} punto${seleccionados !== 1 ? 's' : ''} seleccionado${seleccionados !== 1 ? 's' : ''}`;
                });
            });

        } catch (err) {
            container.innerHTML = '<div class="puntos-selector-empty">Error al cargar puntos</div>';
        }
    }

    // Establecer fecha por defecto como hoy
    function setFechaHoy() {
        const input = document.getElementById('ruta-fecha');
        const hoy = new Date();
        const yyyy = hoy.getFullYear();
        const mm = String(hoy.getMonth() + 1).padStart(2, '0');
        const dd = String(hoy.getDate()).padStart(2, '0');
        input.value = `${yyyy}-${mm}-${dd}`;
    }

    // =============================================
    //  TABLA DE RUTAS
    // =============================================
    const tablaRutas = document.getElementById('tabla-rutas');
    const contadorRutas = document.getElementById('contador-rutas');
    const tablaHistorial = document.getElementById('tabla-historial');
    const contadorHistorial = document.getElementById('contador-historial');

    async function cargarRutas() {
        const rutas = await RutasService.obtenerTodas();

        // Ordenar por fecha descendente
        rutas.sort((a, b) => (b.fecha || '').localeCompare(a.fecha || ''));

        renderTablaRutas(rutas, tablaRutas, contadorRutas);
        renderTablaRutas(rutas, tablaHistorial, contadorHistorial);
    }

    function renderTablaRutas(rutas, contenedor, contador) {
        contador.textContent = `${rutas.length} ruta${rutas.length !== 1 ? 's' : ''}`;

        if (rutas.length === 0) {
            contenedor.innerHTML = `
                <div class="rutas-empty-state">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                            d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7">
                        </path>
                    </svg>
                    <p>No hay rutas asignadas aún.</p>
                </div>`;
            return;
        }

        const estadoBadge = (estado) => {
            switch (estado) {
                case 'Pendiente': return 'badge badge-pendiente';
                case 'En curso': return 'badge badge-en-curso';
                case 'Finalizada': return 'badge badge-finalizada';
                default: return 'badge';
            }
        };

        const formatFecha = (fecha) => {
            if (!fecha) return '-';
            // Manejar tanto formato ISO como string simple
            try {
                const d = new Date(fecha + 'T00:00:00');
                return d.toLocaleDateString('es-CL', { day: '2-digit', month: '2-digit', year: 'numeric' });
            } catch {
                return fecha;
            }
        };

        const renderPuntos = (puntos) => {
            if (!puntos || puntos.length === 0) return '<span style="color: var(--rc-gray-400);">Sin puntos</span>';
            return `<div class="puntos-tags">${puntos.map(pid => {
                const nombre = puntosMap[pid] || pid;
                return `<span class="punto-tag" title="${nombre}">${nombre}</span>`;
            }).join('')}</div>`;
        };

        contenedor.innerHTML = `
            <table class="rutas-table">
                <thead>
                    <tr>
                        <th>Fecha</th>
                        <th>Camión</th>
                        <th>Chofer</th>
                        <th>Ayudante</th>
                        <th>Puntos</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    ${rutas.map(r => `
                        <tr>
                            <td><strong>${formatFecha(r.fecha)}</strong></td>
                            <td>${r.camion_asignado || '-'}</td>
                            <td>${r.chofer_asignado || '-'}</td>
                            <td>${r.ayudante_asignado || '-'}</td>
                            <td>${renderPuntos(r.puntos)}</td>
                            <td><span class="${estadoBadge(r.estado)}">${r.estado || 'Pendiente'}</span></td>
                            <td>
                                <div class="action-btns">
                                    <button class="btn-danger" onclick="eliminarRuta('${r.id}')">Eliminar</button>
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    }

    // =============================================
    //  FORMULARIO ASIGNAR RUTA
    // =============================================
    const formRuta = document.getElementById('form-ruta');

    formRuta.addEventListener('submit', async (e) => {
        e.preventDefault();
        let valid = true;
        clearAllFormErrors();

        const fecha = document.getElementById('ruta-fecha').value;
        const camion = document.getElementById('ruta-camion').value;
        const chofer = document.getElementById('ruta-chofer').value;
        const ayudante = document.getElementById('ruta-ayudante').value;
        const estado = document.getElementById('ruta-estado').value;

        // Obtener puntos seleccionados
        const puntosCheckboxes = document.querySelectorAll('#puntos-selector input[type="checkbox"]:checked');
        const puntosSeleccionados = Array.from(puntosCheckboxes).map(cb => cb.value);

        // Validaciones
        if (!fecha) {
            showError('ruta-fecha', 'error-fecha');
            valid = false;
        }
        if (!camion) {
            showError('ruta-camion', 'error-camion');
            valid = false;
        }
        if (!chofer) {
            showError('ruta-chofer', 'error-chofer');
            valid = false;
        }
        if (!ayudante) {
            showError('ruta-ayudante', 'error-ayudante');
            valid = false;
        }
        if (puntosSeleccionados.length === 0) {
            document.getElementById('puntos-selector').classList.add('error');
            document.getElementById('error-puntos').classList.add('visible');
            valid = false;
        }

        if (!valid) return;

        const btn = document.getElementById('btn-asignar-ruta');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path></svg> Asignando...';

        const resultado = await RutasService.registrar({
            fecha,
            camion_asignado: camion,
            chofer_asignado: chofer,
            ayudante_asignado: ayudante,
            puntos: puntosSeleccionados,
            estado
        });

        btn.disabled = false;
        btn.innerHTML = '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg> Asignar Ruta';

        if (resultado.error) {
            showToast(resultado.error, 'error');
            return;
        }

        showToast('Ruta asignada correctamente', 'success');
        formRuta.reset();
        setFechaHoy();
        // Deseleccionar todos los checkboxes
        document.querySelectorAll('#puntos-selector input[type="checkbox"]').forEach(cb => cb.checked = false);
        document.getElementById('puntos-counter').textContent = '0 puntos seleccionados';

        await cargarRutas();
    });

    // =============================================
    //  ELIMINAR RUTA
    // =============================================
    window.eliminarRuta = (rutaId) => {
        document.getElementById('modal-nombre-item').textContent = `Se eliminará la ruta "${rutaId}" permanentemente.`;
        const modal = document.getElementById('modal-eliminar');
        modal.classList.add('visible');

        document.getElementById('modal-confirmar').onclick = async () => {
            modal.classList.remove('visible');
            const resultado = await RutasService.eliminar(rutaId);
            if (resultado.error) {
                showToast(resultado.error, 'error');
            } else {
                showToast('Ruta eliminada correctamente', 'success');
                await cargarRutas();
            }
        };
    };

    // ========== MODAL CANCELAR ==========
    document.getElementById('modal-cancelar').addEventListener('click', () => {
        document.getElementById('modal-eliminar').classList.remove('visible');
    });

    // ========== ANIMACIÓN SPIN ==========
    const style = document.createElement('style');
    style.textContent = `
        @keyframes spin { to { transform: rotate(360deg); } }
        .animate-spin { animation: spin 1s linear infinite; }
    `;
    document.head.appendChild(style);

    // ========== SALIR (CERRAR SESIÓN) ==========
    const btnSalir = document.getElementById('btn-salir');
    if (btnSalir) {
        btnSalir.addEventListener('click', () => {
            localStorage.removeItem('currentUser');
            showToast('Cerrando sesión...', 'info');
            setTimeout(() => {
                window.location.href = 'landing.html';
            }, 800);
        });
    }

    // ========== CARGA INICIAL ==========
    setFechaHoy();
    cargarSelectCamiones();
    cargarSelectChoferes();
    cargarSelectAyudantes();
    cargarPuntosCheckboxes();
    cargarRutas();
});
