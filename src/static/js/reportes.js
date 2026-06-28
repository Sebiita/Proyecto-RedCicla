/**
 * RedCicla — Reportes de Rendimiento (reportes.js)
 * Consume el endpoint /reportes/rendimiento y renderiza las métricas.
 */

const API_BASE_URL = window.location.origin;

// Referencias a elementos del DOM
const elFechaInicio = document.getElementById('filtro-fecha-inicio');
const elFechaFin = document.getElementById('filtro-fecha-fin');
const elCamion = document.getElementById('filtro-camion');
const elChofer = document.getElementById('filtro-chofer');
const btnGenerar = document.getElementById('btn-generar-reporte');
const btnLimpiar = document.getElementById('btn-limpiar-filtros');

const elMetricTotalRutas = document.getElementById('metric-total-rutas');
const elMetricPesoTotal = document.getElementById('metric-peso-total');
const elMetricPesoPromedio = document.getElementById('metric-peso-promedio');
const elMetricRutasFinalizadas = document.getElementById('metric-rutas-finalizadas');
const elMetricTiempoTotal = document.getElementById('metric-tiempo-total');
const elMetricDistanciaTotal = document.getElementById('metric-distancia-total');
const elMetricEficiencia = document.getElementById('metric-eficiencia');

const elEstadosGrid = document.getElementById('estados-grid');
const elTablaCamiones = document.getElementById('tabla-camiones');
const elTablaConductores = document.getElementById('tabla-conductores');

/**
 * Muestra un toast de notificación.
 */
function mostrarToast(mensaje, tipo = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${tipo}`;
    toast.textContent = mensaje;
    container.appendChild(toast);

    setTimeout(() => {
        toast.remove();
    }, 3000);
}

/**
 * Construye la query string a partir de los filtros seleccionados.
 */
function construirQuery() {
    const params = new URLSearchParams();
    if (elFechaInicio.value) params.append('fecha_inicio', elFechaInicio.value);
    if (elFechaFin.value) params.append('fecha_fin', elFechaFin.value);
    if (elCamion.value.trim()) params.append('camion_asignado', elCamion.value.trim());
    if (elChofer.value.trim()) params.append('chofer_asignado', elChofer.value.trim());
    return params.toString();
}

/**
 * Formatea un número como miles con separador.
 */
function formatearNumero(valor) {
    if (valor === null || valor === undefined || isNaN(valor)) return '-';
    return Number(valor).toLocaleString('es-CL', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

/**
 * Renderiza la sección de estados.
 */
function renderizarEstados(rutasPorEstado) {
    elEstadosGrid.innerHTML = '';
    const estados = Object.entries(rutasPorEstado);

    if (estados.length === 0) {
        elEstadosGrid.innerHTML = '<p class="reportes-empty">No hay datos de estados.</p>';
        return;
    }

    estados.forEach(([nombre, cantidad]) => {
        const card = document.createElement('div');
        card.className = 'estado-card';
        card.innerHTML = `
            <span class="estado-nombre">${nombre}</span>
            <span class="estado-cantidad">${formatearNumero(cantidad)}</span>
        `;
        elEstadosGrid.appendChild(card);
    });
}

/**
 * Renderiza la tabla de rendimiento por camión.
 */
function renderizarTablaCamiones(rendimiento) {
    elTablaCamiones.innerHTML = '';

    if (!rendimiento || rendimiento.length === 0) {
        elTablaCamiones.innerHTML = '<p class="reportes-empty">No hay datos de camiones para el período seleccionado.</p>';
        return;
    }

    const table = document.createElement('table');
    table.className = 'reportes-table';
    table.innerHTML = `
        <thead>
            <tr>
                <th>Patente</th>
                <th class="text-right">Capacidad (kg)</th>
                <th class="text-right">Kilos recogidos</th>
                <th class="text-right">Rendimiento</th>
                <th class="text-right">Rutas asignadas</th>
            </tr>
        </thead>
        <tbody>
            ${rendimiento.map(item => `
                <tr>
                    <td>${item.patente}</td>
                    <td class="text-right">${formatearNumero(item.capacidad)}</td>
                    <td class="text-right">${formatearNumero(item.kilos_recogidos)}</td>
                    <td class="text-right">${formatearNumero(item.rendimiento)}</td>
                    <td class="text-right">${formatearNumero(item.rutas_asignadas)}</td>
                </tr>
            `).join('')}
        </tbody>
    `;
    elTablaCamiones.appendChild(table);
}

/**
 * Renderiza la tabla de eficiencia por conductor.
 */
function renderizarTablaConductores(conductores) {
    elTablaConductores.innerHTML = '';

    if (!conductores || conductores.length === 0) {
        elTablaConductores.innerHTML = '<p class="reportes-empty">No hay datos de conductores para el período seleccionado.</p>';
        return;
    }

    const table = document.createElement('table');
    table.className = 'reportes-table';
    table.innerHTML = `
        <thead>
            <tr>
                <th>Correo del chofer</th>
                <th class="text-right">Rutas realizadas</th>
                <th class="text-right">Kilos recogidos</th>
                <th class="text-right">Peso promedio / ruta</th>
            </tr>
        </thead>
        <tbody>
            ${conductores.map(item => `
                <tr>
                    <td>${item.chofer_email}</td>
                    <td class="text-right">${formatearNumero(item.rutas_realizadas)}</td>
                    <td class="text-right">${formatearNumero(item.kilos_recogidos)}</td>
                    <td class="text-right">${formatearNumero(item.peso_promedio_por_ruta)}</td>
                </tr>
            `).join('')}
        </tbody>
    `;
    elTablaConductores.appendChild(table);
}

/**
 * Renderiza todo el reporte en pantalla.
 */
function renderizarReporte(data) {
    if (data.error) {
        mostrarToast(data.error, 'error');
        return;
    }

    elMetricTotalRutas.textContent = formatearNumero(data.total_rutas);
    elMetricPesoTotal.textContent = `${formatearNumero(data.peso_total_recogido_kg)} kg`;
    elMetricPesoPromedio.textContent = `${formatearNumero(data.peso_promedio_por_ruta_kg)} kg`;
    elMetricRutasFinalizadas.textContent = formatearNumero(data.rutas_por_estado?.Finalizada ?? 0);
    elMetricTiempoTotal.textContent = `${formatearNumero(data.tiempo_total_horas)} h`;
    elMetricDistanciaTotal.textContent = `${formatearNumero(data.distancia_total_km)} km`;
    elMetricEficiencia.textContent = `${formatearNumero(data.eficiencia_kg_por_km)} kg/km`;

    renderizarEstados(data.rutas_por_estado || {});
    renderizarTablaCamiones(data.rendimiento_por_camion || []);
    renderizarTablaConductores(data.eficiencia_por_conductor || []);
}

/**
 * Consulta el endpoint de reportes.
 */
async function generarReporte() {
    try {
        btnGenerar.disabled = true;
        btnGenerar.innerHTML = `
            <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Generando...
        `;

        const query = construirQuery();
        const url = `${API_BASE_URL}/reportes/rendimiento${query ? '?' + query : ''}`;

        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }

        const data = await response.json();
        renderizarReporte(data);
        mostrarToast('Reporte generado correctamente', 'success');
    } catch (error) {
        console.error('Error al generar reporte:', error);
        mostrarToast('No se pudo generar el reporte. Intente nuevamente.', 'error');
    } finally {
        btnGenerar.disabled = false;
        btnGenerar.innerHTML = `
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z">
                </path>
            </svg>
            Generar Reporte
        `;
    }
}

/**
 * Limpia los filtros y regenera el reporte sin filtros.
 */
function limpiarFiltros() {
    elFechaInicio.value = '';
    elFechaFin.value = '';
    elCamion.value = '';
    elChofer.value = '';
    generarReporte();
}

// Listeners
btnGenerar.addEventListener('click', generarReporte);
btnLimpiar.addEventListener('click', limpiarFiltros);

// Generar reporte inicial al cargar la página
document.addEventListener('DOMContentLoaded', generarReporte);
