/**
 * puntos-registro.js — Lógica de la pantalla de registro de puntos (HU-03)
 *
 * Dependencias: puntos-service.js (debe cargarse antes)
 */

document.addEventListener('DOMContentLoaded', () => {
    // ========== ELEMENTOS DOM ==========
    const form = document.getElementById('form-registro-punto');
    const tablaContenedor = document.getElementById('tabla-contenedor');
    const contadorPuntos = document.getElementById('contador-puntos');
    const toastContainer = document.getElementById('toast-container');

    // Campos del formulario
    const campos = {
        nombre: document.getElementById('punto-nombre'),
        direccion: document.getElementById('punto-direccion'),
        latitud: document.getElementById('punto-latitud'),
        longitud: document.getElementById('punto-longitud'),
        horario: document.getElementById('punto-horario'),
        estado: document.getElementById('punto-estado')
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

        // Remover después de la animación
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 3000);
    }

    // ========== VALIDACIÓN ==========
    function validarFormulario() {
        let valido = true;

        // Nombre
        if (!campos.nombre.value.trim()) {
            mostrarError('nombre', 'El nombre es obligatorio.');
            valido = false;
        } else {
            limpiarError('nombre');
        }

        // Dirección
        if (!campos.direccion.value.trim()) {
            mostrarError('direccion', 'La dirección es obligatoria.');
            valido = false;
        } else {
            limpiarError('direccion');
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

        // Materiales
        const materialesSeleccionados = document.querySelectorAll('input[name="tipoMaterial"]:checked');
        if (materialesSeleccionados.length === 0) {
            mostrarError('material', 'Selecciona al menos un tipo de material.');
            valido = false;
        } else {
            limpiarError('material');
        }

        return valido;
    }

    function mostrarError(campo, mensaje) {
        const errorEl = document.getElementById(`error-${campo}`);
        if (errorEl) {
            errorEl.textContent = mensaje;
            errorEl.classList.add('visible');
        }
        // Agregar clase error al input si existe
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
        ['nombre', 'direccion', 'latitud', 'longitud', 'material'].forEach(limpiarError);
    }

    // ========== SUBMIT DEL FORMULARIO ==========
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        limpiarTodosErrores();

        if (!validarFormulario()) return;

        // Recoger materiales seleccionados
        const materialesChecked = document.querySelectorAll('input[name="tipoMaterial"]:checked');
        const tipoMaterial = Array.from(materialesChecked).map(cb => cb.value);

        // Construir objeto punto
        const nuevoPunto = {
            nombre: campos.nombre.value.trim(),
            direccion: campos.direccion.value.trim(),
            latitud: parseFloat(campos.latitud.value),
            longitud: parseFloat(campos.longitud.value),
            tipoMaterial: tipoMaterial,
            horario: campos.horario.value.trim() || 'No especificado',
            estado: campos.estado.value
        };

        // Guardar vía servicio
        // TODO: Cuando el backend esté listo, PuntosService.guardar() hará un POST al API
        const puntoGuardado = PuntosService.guardar(nuevoPunto);

        if (puntoGuardado) {
            mostrarToast(`Punto "${puntoGuardado.nombre}" registrado exitosamente.`, 'success');
            form.reset();
            limpiarTodosErrores();
            renderizarTabla();
        } else {
            mostrarToast('Error al registrar el punto. Intenta nuevamente.', 'error');
        }
    });

    // ========== RENDERIZAR TABLA ==========
    function renderizarTabla() {
        // TODO: Cuando el backend esté listo, PuntosService.obtenerTodos() hará un GET al API
        const puntos = PuntosService.obtenerTodos();

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

        // Construir tabla
        let html = `
            <table class="puntos-table">
                <thead>
                    <tr>
                        <th>Nombre</th>
                        <th>Dirección</th>
                        <th>Materiales</th>
                        <th>Horario</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
        `;

        puntos.forEach(punto => {
            const materialesHtml = punto.tipoMaterial
                .map(m => `<span class="material-tag">${m}</span>`)
                .join('');

            const badgeClass = punto.estado === 'activo' ? 'badge-activo' : 'badge-inactivo';
            const estadoTexto = punto.estado === 'activo' ? 'Activo' : 'Inactivo';

            html += `
                <tr>
                    <td style="font-weight: 600; color: var(--rc-gray-800);">${escapeHtml(punto.nombre)}</td>
                    <td>${escapeHtml(punto.direccion)}</td>
                    <td><div class="materiales-tags">${materialesHtml}</div></td>
                    <td>${escapeHtml(punto.horario || 'N/A')}</td>
                    <td><span class="badge ${badgeClass}">${estadoTexto}</span></td>
                    <td>
                        <button class="btn-danger btn-eliminar" data-id="${punto.id}" data-nombre="${escapeHtml(punto.nombre)}">
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
                puntoIdAEliminar = btn.dataset.id;
                modalNombre.textContent = `¿Deseas eliminar "${btn.dataset.nombre}"? Esta acción no se puede deshacer.`;
                modalOverlay.classList.add('visible');
            });
        });
    }

    // ========== MODAL DE ELIMINACIÓN ==========
    modalCancelar.addEventListener('click', () => {
        modalOverlay.classList.remove('visible');
        puntoIdAEliminar = null;
    });

    modalConfirmar.addEventListener('click', () => {
        if (puntoIdAEliminar) {
            // TODO: Cuando el backend esté listo, PuntosService.eliminar() hará un DELETE al API
            const eliminado = PuntosService.eliminar(puntoIdAEliminar);
            if (eliminado) {
                mostrarToast('Punto eliminado correctamente.', 'success');
            } else {
                mostrarToast('Error al eliminar el punto.', 'error');
            }
            renderizarTabla();
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

    // ========== UTILIDADES ==========
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // ========== LIMPIAR ERRORES EN TIEMPO REAL ==========
    Object.values(campos).forEach(input => {
        if (input) {
            input.addEventListener('input', () => {
                input.classList.remove('error');
                const errorEl = input.closest('.form-group')?.querySelector('.error-msg');
                if (errorEl) errorEl.classList.remove('visible');
            });
        }
    });

    // Limpiar error de materiales al seleccionar alguno
    document.querySelectorAll('input[name="tipoMaterial"]').forEach(cb => {
        cb.addEventListener('change', () => {
            limpiarError('material');
        });
    });

    // ========== INICIALIZACIÓN ==========
    renderizarTabla();
});
