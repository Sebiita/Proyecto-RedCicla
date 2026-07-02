/**
 * dashboard-global.js
 * Lógica de renderizado del Dashboard Global de RedCicla.
 *
 * Funcionalidades:
 *  - Carga inicial del dashboard con skeleton loaders
 *  - Auto-refresh configurable (por defecto 30s)
 *  - Tarjetas KPI (rutas, puntos totales, completados, en espera, % global)
 *  - Tarjetas expandibles por ruta con lista de puntos y su estado
 *  - Botón de refresh manual con animación
 *  - Toasts de notificación
 */

// ============================================================
//  CONFIGURACIÓN
// ============================================================
const REFRESH_INTERVAL_MS = 30_000; // 30 segundos
let refreshTimer = null;
let lastData = null;
let rutasExpandidas = new Set(); // Mantener el estado de expansión entre refreshes

// ============================================================
//  INICIALIZACIÓN
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
    cargarDashboard();

    // Auto-refresh
    startAutoRefresh();

    // Botón manual
    const btnRefresh = document.getElementById('btn-refresh');
    if (btnRefresh) {
        btnRefresh.addEventListener('click', () => {
            animateRefreshBtn();
            cargarDashboard();
        });
    }

    // Countdown del próximo refresh
    iniciarCountdown();
});

// ============================================================
//  CARGA DE DATOS
// ============================================================
async function cargarDashboard() {
    try {
        const data = await DashboardService.obtenerHoy();

        if (data.error) {
            mostrarError(data.error);
            return;
        }

        lastData = data;
        renderDashboard(data);
        actualizarTimestamp();
    } catch (err) {
        mostrarError('Error inesperado al cargar el dashboard.');
        console.error(err);
    }
}

// ============================================================
//  RENDER PRINCIPAL
// ============================================================
function renderDashboard(data) {
    renderKPIs(data.resumen, data.fecha);
    renderProgressGlobal(data.resumen);
    renderRutas(data.rutas);
}

// ── KPI Cards ──────────────────────────────────────────────
function renderKPIs(resumen, fecha) {
    const fechaEl = document.getElementById('dash-fecha');
    if (fechaEl) fechaEl.textContent = formatearFecha(fecha);

    setKPI('kpi-rutas',       resumen.total_rutas);
    setKPI('kpi-completados', resumen.total_completados);
    setKPI('kpi-espera',      resumen.total_en_espera);
    setKPI('kpi-total',       resumen.total_puntos);
}

function setKPI(id, valor) {
    const el = document.getElementById(id);
    if (!el) return;
    // Animación numérica suave
    const start = parseInt(el.textContent) || 0;
    animateNumber(el, start, valor, 500);
}

function animateNumber(el, from, to, duration) {
    if (from === to) { el.textContent = to; return; }
    const startTime = performance.now();
    function step(now) {
        const elapsed = now - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic
        el.textContent = Math.round(from + (to - from) * eased);
        if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
}

// ── Progress Global ─────────────────────────────────────────
function renderProgressGlobal(resumen) {
    const pctEl   = document.getElementById('dash-pct-global');
    const barEl   = document.getElementById('dash-bar-global');
    const descEl  = document.getElementById('dash-progress-desc');

    const pct = resumen.porcentaje_global ?? 0;

    if (pctEl) pctEl.textContent = `${pct}%`;
    if (barEl) barEl.style.width = `${pct}%`;
    if (descEl) {
        descEl.textContent =
            `${resumen.total_completados} de ${resumen.total_puntos} puntos recolectados hoy`;
    }
}

// ── Rutas ───────────────────────────────────────────────────
function renderRutas(rutas) {
    const container = document.getElementById('rutas-container');
    if (!container) return;

    container.innerHTML = '';

    if (!rutas || rutas.length === 0) {
        container.innerHTML = `
            <div class="dash-empty">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
                <p>No hay rutas programadas para hoy</p>
                <small>Las rutas creadas con fecha de hoy aparecerán aquí automáticamente.</small>
            </div>`;
        return;
    }

    rutas.forEach((ruta, idx) => {
        const card = crearRutaCard(ruta, idx + 1);
        container.appendChild(card);
    });
}

// ── Crear card de una ruta ───────────────────────────────────
function crearRutaCard(ruta, numero) {
    const card = document.createElement('div');
    card.className = 'ruta-card' + (rutasExpandidas.has(ruta.id) ? ' expanded' : '');
    card.dataset.rutaId = ruta.id;

    const estadoBadgeClass = {
        'Pendiente':  'pendiente',
        'En curso':   'en-curso',
        'Finalizada': 'finalizada',
    }[ruta.estado] || 'pendiente';

    const pct = ruta.porcentaje_avance ?? 0;
    const chofer    = formatearCorreo(ruta.chofer_asignado);
    const ayudante  = formatearCorreo(ruta.ayudante_asignado);

    card.innerHTML = `
        <!-- Header clicable -->
        <div class="ruta-card-header" id="header-${ruta.id}" role="button" aria-expanded="${rutasExpandidas.has(ruta.id)}">
            <div class="ruta-card-header-left">
                <div class="ruta-numero">${numero}</div>
                <div class="ruta-card-meta">
                    <h3>🚛 ${ruta.camion_asignado || 'Sin camión'}</h3>
                    <p>Chofer: ${chofer} · Ayudante: ${ayudante}</p>
                </div>
            </div>
            <div class="ruta-card-header-right">
                <div class="ruta-mini-progress">
                    <div class="ruta-mini-progress-bar">
                        <div class="ruta-mini-progress-fill" style="width: ${pct}%"></div>
                    </div>
                    <span class="ruta-mini-progress-label">${pct}%</span>
                </div>
                <span class="badge-ruta-estado ${estadoBadgeClass}">${ruta.estado}</span>
                <svg class="ruta-toggle-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                </svg>
            </div>
        </div>

        <!-- Cuerpo con puntos -->
        <div class="ruta-puntos-body" id="body-${ruta.id}">
            ${renderPuntosDeRuta(ruta)}
        </div>
    `;

    // Toggle expansión
    const header = card.querySelector('.ruta-card-header');
    header.addEventListener('click', () => toggleRutaCard(card, ruta.id));

    return card;
}

function toggleRutaCard(card, rutaId) {
    const isExpanded = card.classList.toggle('expanded');
    const header = card.querySelector('.ruta-card-header');
    if (header) header.setAttribute('aria-expanded', isExpanded);

    if (isExpanded) {
        rutasExpandidas.add(rutaId);
    } else {
        rutasExpandidas.delete(rutaId);
    }
}

// ── Puntos dentro de una ruta ────────────────────────────────
function renderPuntosDeRuta(ruta) {
    if (!ruta.puntos_estado || ruta.puntos_estado.length === 0) {
        return `<p style="color:var(--rc-gray-400);font-size:0.85rem;margin:0;">
                    Esta ruta no tiene puntos asignados.
                </p>`;
    }

    // Ordenar: en_espera primero, luego completados
    const ordenados = [...ruta.puntos_estado].sort((a, b) => {
        if (a.estado_recoleccion === b.estado_recoleccion) return 0;
        return a.estado_recoleccion === 'en_espera' ? -1 : 1;
    });

    return ordenados.map(p => crearPuntoRow(p)).join('');
}

function crearPuntoRow(punto) {
    const completado = punto.estado_recoleccion === 'completado';
    const urgenciaClass = String(punto.urgencia || 'Normal').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const urgenciaLabel = punto.urgencia || 'Normal';

    const kilosLabel = completado
        ? `<span class="badge-punto-kilos">${punto.kilos_recogidos} kg recolectados</span>`
        : '';

    const tsLabel = completado && punto.timestamp_ficha
        ? `<span style="font-size:0.72rem;color:var(--rc-gray-400)">${formatearHora(punto.timestamp_ficha)}</span>`
        : '';

    return `
        <div class="punto-row">
            <div class="punto-status-dot ${punto.estado_recoleccion}"></div>
            <div class="punto-row-info">
                <div class="punto-row-nombre">
                    ${completado ? '✅' : '⏳'} ${punto.municipalidad || 'Punto sin nombre'}
                </div>
                <div class="punto-row-sub">
                    Cap. máx: ${punto.capacidad_maxima} kg
                    · Cap. actual: ${punto.capacidad_ocupada} kg
                    ${tsLabel ? '· ' + tsLabel.trim() : ''}
                </div>
            </div>
            <div class="punto-row-right">
                ${kilosLabel}
                <span class="badge-urgencia ${urgenciaClass}">${urgenciaLabel}</span>
                <span class="badge-punto ${punto.estado_recoleccion}">
                    ${completado ? 'Completado' : 'En espera'}
                </span>
            </div>
        </div>
    `;
}



// ============================================================
//  AUTO-REFRESH
// ============================================================
function startAutoRefresh() {
    if (refreshTimer) clearInterval(refreshTimer);
    refreshTimer = setInterval(() => {
        cargarDashboard();
        resetCountdown();
    }, REFRESH_INTERVAL_MS);
}

let countdownEl = null;
let countdownValue = REFRESH_INTERVAL_MS / 1000;
let countdownInterval = null;

function iniciarCountdown() {
    countdownEl = document.getElementById('refresh-countdown');
    resetCountdown();
}

function resetCountdown() {
    countdownValue = REFRESH_INTERVAL_MS / 1000;
    if (countdownInterval) clearInterval(countdownInterval);
    countdownInterval = setInterval(() => {
        countdownValue--;
        if (countdownEl) countdownEl.textContent = `${countdownValue}s`;
        if (countdownValue <= 0) {
            clearInterval(countdownInterval);
        }
    }, 1000);
}

// ============================================================
//  ANIMACIÓN BOTÓN REFRESH
// ============================================================
function animateRefreshBtn() {
    const btn = document.getElementById('btn-refresh');
    if (!btn) return;
    btn.classList.add('refreshing');
    setTimeout(() => btn.classList.remove('refreshing'), 700);
}

// ============================================================
//  TOASTS
// ============================================================
function mostrarError(mensaje) {
    const container = document.getElementById('toast-container');
    if (!container) { console.error(mensaje); return; }
    const toast = document.createElement('div');
    toast.className = 'toast error';
    toast.textContent = `⚠️ ${mensaje}`;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// ============================================================
//  UTILIDADES
// ============================================================
function formatearFecha(fechaStr) {
    if (!fechaStr) return '';
    // "2026-06-30" → "lunes 30 de junio de 2026"
    try {
        const [y, m, d] = fechaStr.split('-').map(Number);
        const fecha = new Date(y, m - 1, d);
        return fecha.toLocaleDateString('es-CL', {
            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
        });
    } catch {
        return fechaStr;
    }
}

function formatearCorreo(correo) {
    if (!correo) return '—';
    // "juan.perez@redcicla.cl" → "juan.perez"
    return correo.split('@')[0];
}

function formatearHora(isoStr) {
    if (!isoStr) return '';
    try {
        const fecha = new Date(isoStr);
        return fecha.toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' });
    } catch {
        return isoStr;
    }
}

function actualizarTimestamp() {
    const el = document.getElementById('last-update');
    if (!el) return;
    const ahora = new Date().toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    el.textContent = `Última actualización: ${ahora}`;
}
