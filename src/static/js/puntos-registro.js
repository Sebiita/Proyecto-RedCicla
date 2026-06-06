/**
 * puntos-registro.js — Lógica de la pantalla de registro de puntos (HU-03)
 *
 * Dependencias: puntos-service.js (debe cargarse antes)
 *
 * Conectado al backend FastAPI:
 *   POST   /puntos/registrar  → Crear punto
 *   GET    /puntos/obtener    → Listar todos
 *   DELETE /puntos/eliminar/{id} → Eliminar punto
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
    const form = document.getElementById('form-registro-punto');
    const tablaContenedor = document.getElementById('tabla-contenedor');
    const contadorPuntos = document.getElementById('contador-puntos');
    const toastContainer = document.getElementById('toast-container');

    // Campos del formulario (coinciden con el modelo del backend)
    const campos = {
        municipalidad: document.getElementById('punto-municipalidad'),
        latitud: document.getElementById('punto-latitud'),
        longitud: document.getElementById('punto-longitud'),
        estado: document.getElementById('punto-estado'),
        urgencia: document.getElementById('punto-urgencia'),
        'capacidad-maxima': document.getElementById('punto-capacidad-maxima'),
        'capacidad-ocupada': document.getElementById('punto-capacidad-ocupada')
    };

    // Modal
    const modalOverlay = document.getElementById('modal-eliminar');
    const modalNombre = document.getElementById('modal-nombre-punto');
    const modalCancelar = document.getElementById('modal-cancelar');
    const modalConfirmar = document.getElementById('modal-confirmar');
    let puntoIdAEliminar = null;

    // ========== TOAST NOTIFICATIONS ==========
    function mostrarToast(mensaje, tipo = 'success') {
        const toast = document.createElement('div');
        toast.className = `toast ${tipo}`;
        toast.textContent = mensaje;
        toastContainer.appendChild(toast);

        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 3000);
    }

    // ========== VALIDACIÓN ==========
    function validarFormulario() {
        let valido = true;

        // Municipalidad
        if (!campos.municipalidad.value.trim()) {
            mostrarError('municipalidad', 'La municipalidad es obligatoria.');
            valido = false;
        } else {
            limpiarError('municipalidad');
        }

        // Latitud
        const lat = parseFloat(campos.latitud.value);
        if (isNaN(lat) || lat < -90 || lat > 90) {
            mostrarError('latitud', 'Latitud debe estar entre -90 y 90.');
            valido = false;
        } else {
            limpiarError('latitud');
        }

        // Longitud
        const lng = parseFloat(campos.longitud.value);
        if (isNaN(lng) || lng < -180 || lng > 180) {
            mostrarError('longitud', 'Longitud debe estar entre -180 y 180.');
            valido = false;
        } else {
            limpiarError('longitud');
        }

        // Capacidad máxima
        const capMax = parseFloat(campos['capacidad-maxima'].value);
        if (isNaN(capMax) || capMax <= 0) {
            mostrarError('capacidad-maxima', 'Capacidad máxima debe ser mayor a 0.');
            valido = false;
        } else {
            limpiarError('capacidad-maxima');
        }

        // Capacidad ocupada
        const capOcup = parseFloat(campos['capacidad-ocupada'].value || '0');
        if (isNaN(capOcup) || capOcup < 0) {
            mostrarError('capacidad-ocupada', 'Capacidad ocupada no puede ser negativa.');
            valido = false;
        } else if (capOcup > capMax) {
            mostrarError('capacidad-ocupada', 'Capacidad ocupada no puede superar la máxima.');
            valido = false;
        } else {
            limpiarError('capacidad-ocupada');
        }

        return valido;
    }

    function mostrarError(campo, mensaje) {
        const errorEl = document.getElementById(`error-${campo}`);
        if (errorEl) {
            errorEl.textContent = mensaje;
            errorEl.classList.add('visible');
        }
        if (campos[campo]) {
            campos[campo].classList.add('error');
        }
    }

    function limpiarError(campo) {
        const errorEl = document.getElementById(`error-${campo}`);
        if (errorEl) {
            errorEl.classList.remove('visible');
        }
        if (campos[campo]) {
            campos[campo].classList.remove('error');
        }
    }

    function limpiarTodosErrores() {
        ['municipalidad', 'latitud', 'longitud', 'capacidad-maxima', 'capacidad-ocupada'].forEach(limpiarError);
    }

    // ========== SUBMIT DEL FORMULARIO ==========
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        limpiarTodosErrores();

        if (!validarFormulario()) return;

        // Construir objeto punto según modelo del backend (PuntoRecicljeCrear)
        const nuevoPunto = {
            municipalidad: campos.municipalidad.value.trim(),
            latitud: parseFloat(campos.latitud.value),
            longitud: parseFloat(campos.longitud.value),
            estado: campos.estado.value,
            urgencia: campos.urgencia.value,
            capacidad_maxima: parseFloat(campos['capacidad-maxima'].value),
            capacidad_ocupada: parseFloat(campos['capacidad-ocupada'].value || '0')
        };

        // Deshabilitar botón mientras se procesa
        const btnRegistrar = document.getElementById('btn-registrar');
        btnRegistrar.disabled = true;
        btnRegistrar.textContent = 'Registrando...';

        try {
            const resultado = await PuntosService.guardar(nuevoPunto);

            if (resultado.error) {
                mostrarToast(`Error: ${resultado.error}`, 'error');
            } else {
                mostrarToast(`Punto en "${nuevoPunto.municipalidad}" registrado exitosamente.`, 'success');
                form.reset();
                // Restaurar valor por defecto del select de urgencia
                campos.urgencia.value = 'Normal';
                campos['capacidad-ocupada'].value = '0';
                limpiarTodosErrores();
                await renderizarTabla();
            }
        } catch (error) {
            mostrarToast('Error de conexión con el servidor.', 'error');
            console.error('Error al registrar punto:', error);
        } finally {
            btnRegistrar.disabled = false;
            btnRegistrar.innerHTML = `
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M12 4v16m8-8H4"></path>
                </svg>
                Registrar Punto
            `;
        }
    });

    // ========== RENDERIZAR TABLA ==========
    async function renderizarTabla() {
        const puntos = await PuntosService.obtenerTodos();

        // Actualizar contador
        contadorPuntos.textContent = `${puntos.length} punto${puntos.length !== 1 ? 's' : ''}`;

        // Si no hay puntos, mostrar estado vacío
        if (puntos.length === 0) {
            tablaContenedor.innerHTML = `
                <div class="empty-state">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                    <p>No hay puntos de reciclaje registrados.</p>
                    <p style="font-size: 0.75rem; margin-top: 0.5rem; color: var(--rc-gray-400);">
                        Usa el formulario para registrar el primero.
                    </p>
                </div>
            `;
            return;
        }

        // Construir tabla con campos del backend
        let html = `
            <table class="puntos-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Municipalidad</th>
                        <th>Coordenadas</th>
                        <th>Estado</th>
                        <th>Urgencia</th>
                        <th>Capacidad</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
        `;

        puntos.forEach(punto => {
            // Badge de estado
            let badgeClass = 'badge-activo';
            if (punto.estado === 'Inactivo') badgeClass = 'badge-inactivo';
            else if (punto.estado === 'Mantencion') badgeClass = 'badge-inactivo';

            // Badge de urgencia
            let urgenciaClass = '';
            switch (punto.urgencia) {
                case 'Baja': urgenciaClass = 'badge-activo'; break;
                case 'Normal': urgenciaClass = ''; break;
                case 'Alta': urgenciaClass = 'badge-inactivo'; break;
                case 'Crítica': urgenciaClass = 'badge-inactivo'; break;
                default: urgenciaClass = '';
            }

            // Porcentaje de capacidad
            const porcCapacidad = punto.capacidad_maxima > 0
                ? Math.round((punto.capacidad_ocupada / punto.capacidad_maxima) * 100)
                : 0;

            html += `
                <tr>
                    <td style="font-weight: 600; color: var(--rc-gray-800);">#${punto.id}</td>
                    <td style="font-weight: 600;">${escapeHtml(punto.municipalidad)}</td>
                    <td style="font-size: 0.75rem; color: var(--rc-gray-500);">${punto.latitud.toFixed(4)}, ${punto.longitud.toFixed(4)}</td>
                    <td><span class="badge ${badgeClass}">${escapeHtml(punto.estado)}</span></td>
                    <td><span class="badge ${urgenciaClass}">${escapeHtml(punto.urgencia)}</span></td>
                    <td>
                        <div style="font-size: 0.75rem;">
                            ${punto.capacidad_ocupada}/${punto.capacidad_maxima} kg
                            <div style="background: var(--rc-gray-200); border-radius: 9999px; height: 4px; margin-top: 2px;">
                                <div style="background: ${porcCapacidad > 80 ? 'var(--rc-red-500)' : 'var(--rc-green-600)'}; border-radius: 9999px; height: 100%; width: ${Math.min(porcCapacidad, 100)}%;"></div>
                            </div>
                        </div>
                    </td>
                    <td>
                        <button class="btn-danger btn-eliminar" data-id="${punto.id}" data-nombre="${escapeHtml(punto.municipalidad)}">
                            Eliminar
                        </button>
                    </td>
                </tr>
            `;
        });

        html += '</tbody></table>';
        tablaContenedor.innerHTML = html;

        // Event listeners para botones eliminar
        document.querySelectorAll('.btn-eliminar').forEach(btn => {
            btn.addEventListener('click', () => {
                puntoIdAEliminar = parseInt(btn.dataset.id);
                modalNombre.textContent = `¿Deseas eliminar el punto #${btn.dataset.id} (${btn.dataset.nombre})? Esta acción no se puede deshacer.`;
                modalOverlay.classList.add('visible');
            });
        });
    }

    // ========== MODAL DE ELIMINACIÓN ==========
    modalCancelar.addEventListener('click', () => {
        modalOverlay.classList.remove('visible');
        puntoIdAEliminar = null;
    });

    modalConfirmar.addEventListener('click', async () => {
        if (puntoIdAEliminar !== null) {
            const resultado = await PuntosService.eliminar(puntoIdAEliminar);
            if (resultado.error) {
                mostrarToast(`Error: ${resultado.error}`, 'error');
            } else {
                mostrarToast('Punto eliminado correctamente.', 'success');
            }
            await renderizarTabla();
        }
        modalOverlay.classList.remove('visible');
        puntoIdAEliminar = null;
    });

    // Cerrar modal al hacer clic fuera
    modalOverlay.addEventListener('click', (e) => {
        if (e.target === modalOverlay) {
            modalOverlay.classList.remove('visible');
            puntoIdAEliminar = null;
        }
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

    // ========== LIMPIAR ERRORES EN TIEMPO REAL ==========
    Object.entries(campos).forEach(([key, input]) => {
        if (input) {
            input.addEventListener('input', () => {
                input.classList.remove('error');
                const errorEl = document.getElementById(`error-${key}`);
                if (errorEl) errorEl.classList.remove('visible');
            });
        }
    });

    // ========== INICIALIZACIÓN ==========
    renderizarTabla();
});
