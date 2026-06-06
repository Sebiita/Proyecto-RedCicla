/**
 * vehiculos-personal.js
 * Lógica de UI para la página de Vehículos & Personal.
 * Gestiona tabs, formularios, tablas, modales y toasts.
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
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

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

    function clearAllErrors(prefix) {
        document.querySelectorAll(`[id^="${prefix}"] .error`).forEach(el => el.classList.remove('error'));
        document.querySelectorAll(`[id^="${prefix}"] .error-msg`).forEach(el => el.classList.remove('visible'));
    }

    // =============================================
    //  VEHÍCULOS (CAMIONES)
    // =============================================
    const formCamion = document.getElementById('form-camion');
    const tablaCamiones = document.getElementById('tabla-camiones');
    const contadorCamiones = document.getElementById('contador-camiones');

    async function cargarCamiones() {
        const camiones = await CamionesService.obtenerTodos();
        renderTabla_camiones(camiones);
    }

    function renderTabla_camiones(camiones) {
        contadorCamiones.textContent = `${camiones.length} vehículo${camiones.length !== 1 ? 's' : ''}`;

        if (camiones.length === 0) {
            tablaCamiones.innerHTML = `
                <div class="empty-state">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                            d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                            d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10m10 0h-3m3 0h2m-2 0V6m0 0h4l3 5v5a1 1 0 01-1 1h-1"></path>
                    </svg>
                    <p>No hay vehículos registrados aún.</p>
                </div>`;
            return;
        }

        const badgeClass = (estado) => {
            switch (estado) {
                case 'Operativo': return 'badge badge-operativo';
                case 'Mantencion': return 'badge badge-mantencion';
                case 'Fuera de servicio': return 'badge badge-fuera';
                default: return 'badge';
            }
        };

        tablaCamiones.innerHTML = `
            <table class="vp-table">
                <thead>
                    <tr>
                        <th>Patente</th>
                        <th>Capacidad</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    ${camiones.map(c => `
                        <tr>
                            <td><strong>${c.patente}</strong></td>
                            <td>${c.capacidad} kg</td>
                            <td><span class="${badgeClass(c.estado_mantencion)}">${c.estado_mantencion}</span></td>
                            <td>
                                <div class="action-btns">
                                    <button class="btn-danger" onclick="eliminarCamion('${c.patente}')">Eliminar</button>
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    }

    formCamion.addEventListener('submit', async (e) => {
        e.preventDefault();
        let valid = true;

        const patente = document.getElementById('camion-patente').value.trim();
        const capacidad = parseFloat(document.getElementById('camion-capacidad').value);
        const estado = document.getElementById('camion-estado').value;

        // Validaciones
        clearAllErrors('form-camion');

        if (!patente) {
            showError('camion-patente', 'error-patente');
            valid = false;
        }
        if (isNaN(capacidad) || capacidad <= 0) {
            showError('camion-capacidad', 'error-capacidad');
            valid = false;
        }

        if (!valid) return;

        const btn = document.getElementById('btn-registrar-camion');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path></svg> Registrando...';

        const resultado = await CamionesService.registrar({
            patente,
            capacidad,
            estado_mantencion: estado
        });

        btn.disabled = false;
        btn.innerHTML = '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg> Registrar Vehículo';

        if (resultado.error) {
            showToast(resultado.error, 'error');
            return;
        }

        showToast('Vehículo registrado correctamente', 'success');
        formCamion.reset();
        await cargarCamiones();
    });

    // Función global para el onclick de eliminar
    window.eliminarCamion = (patente) => {
        document.getElementById('modal-nombre-item').textContent = `Se eliminará el vehículo con patente "${patente}".`;
        const modal = document.getElementById('modal-eliminar');
        modal.classList.add('visible');

        document.getElementById('modal-confirmar').onclick = async () => {
            modal.classList.remove('visible');
            const resultado = await CamionesService.eliminar(patente);
            if (resultado.error) {
                showToast(resultado.error, 'error');
            } else {
                showToast('Vehículo eliminado correctamente', 'success');
                await cargarCamiones();
            }
        };
    };

    // =============================================
    //  PERSONAL (CHOFERES & AYUDANTES)
    // =============================================
    const formPersonal = document.getElementById('form-personal');
    const tablaPersonal = document.getElementById('tabla-personal');
    const contadorPersonal = document.getElementById('contador-personal');

    async function cargarPersonal() {
        const personal = await PersonalService.obtenerPersonalOperativo();
        renderTabla_personal(personal);
    }

    function renderTabla_personal(personal) {
        contadorPersonal.textContent = `${personal.length} persona${personal.length !== 1 ? 's' : ''}`;

        if (personal.length === 0) {
            tablaPersonal.innerHTML = `
                <div class="empty-state">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                    </svg>
                    <p>No hay personal operativo registrado aún.</p>
                </div>`;
            return;
        }

        const rolBadge = (rol) => {
            return rol === 'Chofer' ? 'badge badge-chofer' : 'badge badge-ayudante';
        };

        const estadoBadge = (estado) => {
            return estado === 'Activo' ? 'badge badge-activo' : 'badge badge-inactivo';
        };

        tablaPersonal.innerHTML = `
            <table class="vp-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Correo</th>
                        <th>Rol</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    ${personal.map(p => `
                        <tr>
                            <td>${p.id || '-'}</td>
                            <td><strong>${p.nombre} ${p.apellido}</strong></td>
                            <td>${p.correo}</td>
                            <td><span class="${rolBadge(p.rol)}">${p.rol}</span></td>
                            <td><span class="${estadoBadge(p.estado)}">${p.estado}</span></td>
                            <td>
                                <div class="action-btns">
                                    <button class="btn-danger" onclick="eliminarPersonal('${p.correo}')">Eliminar</button>
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    }

    formPersonal.addEventListener('submit', async (e) => {
        e.preventDefault();
        let valid = true;

        const nombre = document.getElementById('personal-nombre').value.trim();
        const apellido = document.getElementById('personal-apellido').value.trim();
        const correo = document.getElementById('personal-correo').value.trim();
        const rol = document.getElementById('personal-rol').value;
        const contraseña = document.getElementById('personal-password').value;
        const estado = document.getElementById('personal-estado').value;

        // Validaciones
        clearAllErrors('form-personal');

        if (!nombre || nombre.length < 2) {
            showError('personal-nombre', 'error-nombre');
            valid = false;
        }
        if (!apellido || apellido.length < 2) {
            showError('personal-apellido', 'error-apellido');
            valid = false;
        }
        if (!correo || !correo.includes('@')) {
            showError('personal-correo', 'error-correo');
            valid = false;
        }
        if (!contraseña || contraseña.length < 6) {
            showError('personal-password', 'error-password');
            valid = false;
        }

        if (!valid) return;

        const btn = document.getElementById('btn-registrar-personal');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path></svg> Registrando...';

        const resultado = await PersonalService.registrar({
            nombre,
            apellido,
            correo,
            rol,
            'contraseña': contraseña,
            estado
        });

        btn.disabled = false;
        btn.innerHTML = '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg> Registrar Personal';

        if (resultado.error) {
            showToast(resultado.error, 'error');
            return;
        }

        showToast('Personal registrado correctamente', 'success');
        formPersonal.reset();
        await cargarPersonal();
    });

    // Función global para el onclick de eliminar personal
    window.eliminarPersonal = (correo) => {
        document.getElementById('modal-nombre-item').textContent = `Se eliminará al usuario "${correo}".`;
        const modal = document.getElementById('modal-eliminar');
        modal.classList.add('visible');

        document.getElementById('modal-confirmar').onclick = async () => {
            modal.classList.remove('visible');
            const resultado = await PersonalService.eliminar(correo);
            if (resultado.error) {
                showToast(resultado.error, 'error');
            } else {
                showToast('Personal eliminado correctamente', 'success');
                await cargarPersonal();
            }
        };
    };

    // ========== MODAL CANCELAR ==========
    document.getElementById('modal-cancelar').addEventListener('click', () => {
        document.getElementById('modal-eliminar').classList.remove('visible');
    });

    // ========== CARGA INICIAL ==========
    cargarCamiones();
    cargarPersonal();

    // ========== ANIMACIÓN SPIN (CSS inline para el spinner) ==========
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
});
