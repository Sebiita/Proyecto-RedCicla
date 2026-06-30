import 'package:flutter/material.dart';
import '../services/reporte_service.dart';

class ReportesRendimientoScreen extends StatefulWidget {
  const ReportesRendimientoScreen({super.key});

  @override
  State<ReportesRendimientoScreen> createState() =>
      _ReportesRendimientoScreenState();
}

class _ReportesRendimientoScreenState
    extends State<ReportesRendimientoScreen> {
  // ── Estado de carga ──────────────────────────────────────────
  bool _cargando = false;
  String? _error;

  // ── Filtros ──────────────────────────────────────────────────
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _camionCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();

  // ── Datos del reporte ────────────────────────────────────────
  Map<String, dynamic>? _reporte;

  @override
  void initState() {
    super.initState();
    // Al entrar, generar reporte sin filtros
    _generarReporte();
  }

  @override
  void dispose() {
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _camionCtrl.dispose();
    _choferCtrl.dispose();
    super.dispose();
  }

  Future<void> _generarReporte() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final reporte = await ReporteService.obtenerReporteRendimiento(
      fechaInicio: _fechaInicioCtrl.text.trim(),
      fechaFin: _fechaFinCtrl.text.trim(),
      camionAsignado: _camionCtrl.text.trim(),
      choferAsignado: _choferCtrl.text.trim(),
    );

    if (!mounted) return;

    if (reporte == null) {
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el reporte. Verifica tu conexión.';
      });
      return;
    }

    if (reporte['_error_auth'] == true) {
      setState(() {
        _cargando = false;
        _error = reporte['_mensaje']?.toString() ??
            'No tienes permisos para ver este reporte.';
      });
      return;
    }

    setState(() {
      _reporte = reporte;
      _cargando = false;
    });
  }

  void _limpiarFiltros() {
    _fechaInicioCtrl.clear();
    _fechaFinCtrl.clear();
    _camionCtrl.clear();
    _choferCtrl.clear();
    _generarReporte();
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      final fechaStr =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      controller.text = fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Reportes de Rendimiento',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_cargando)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _generarReporte,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: _cargando && _reporte == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Cargando reporte...'),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros
                  _buildFiltrosCard(),
                  const SizedBox(height: 20),

                  // Error
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Métricas
                  if (_reporte != null) ...[
                    _buildMetricasCards(),
                    const SizedBox(height: 24),
                    _buildRutasPorEstado(),
                    const SizedBox(height: 24),
                    _buildRendimientoCamiones(),
                    const SizedBox(height: 24),
                    _buildEficienciaConductores(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFiltrosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Fecha inicio',
                  controller: _fechaInicioCtrl,
                  onTap: () => _seleccionarFecha(_fechaInicioCtrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Fecha fin',
                  controller: _fechaFinCtrl,
                  onTap: () => _seleccionarFecha(_fechaFinCtrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Camión (patente)',
            controller: _camionCtrl,
            hint: 'Ej: TEST-01',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Chofer (correo)',
            controller: _choferCtrl,
            hint: 'Ej: chofer@redcicla.cl',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cargando ? null : _generarReporte,
                  icon: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.insert_chart_outlined),
                  label: Text(_cargando ? 'Generando...' : 'Generar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _cargando ? null : _limpiarFiltros,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: Icon(Icons.calendar_today,
                color: Colors.green[600], size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricasCards() {
    final totalRutas = _reporte?['total_rutas'] ?? 0;
    final pesoTotal = _reporte?['peso_total_recogido_kg'] ?? 0.0;
    final pesoPromedio = _reporte?['peso_promedio_por_ruta_kg'] ?? 0.0;
    final rutasFinalizadas =
        (_reporte?['rutas_por_estado'] as Map<String, dynamic>?)?['Finalizada'] ??
            0;
    final tiempoTotal = _reporte?['tiempo_total_horas'] ?? 0.0;
    final distanciaTotal = _reporte?['distancia_total_km'] ?? 0.0;
    final eficienciaKgKm = _reporte?['eficiencia_kg_por_km'] ?? 0.0;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildMetricCard(
              title: 'Total Rutas',
              value: '$totalRutas',
              icon: Icons.route_outlined,
              color: Colors.green[600]!,
              bgColor: Colors.green[50]!,
            ),
            _buildMetricCard(
              title: 'Peso Total',
              value: '${_formatearNumero(pesoTotal)} kg',
              icon: Icons.scale_outlined,
              color: Colors.blue[600]!,
              bgColor: Colors.blue[50]!,
            ),
            _buildMetricCard(
              title: 'Peso Promedio / Ruta',
              value: '${_formatearNumero(pesoPromedio)} kg',
              icon: Icons.trending_up,
              color: Colors.teal[600]!,
              bgColor: Colors.teal[50]!,
            ),
            _buildMetricCard(
              title: 'Finalizadas',
              value: '$rutasFinalizadas',
              icon: Icons.check_circle_outline,
              color: Colors.orange[800]!,
              bgColor: Colors.orange[50]!,
            ),
            _buildMetricCard(
              title: 'Tiempo Total',
              value: '${_formatearNumero(tiempoTotal)} h',
              icon: Icons.timer_outlined,
              color: Colors.purple[600]!,
              bgColor: Colors.purple[50]!,
            ),
            _buildMetricCard(
              title: 'Distancia Total',
              value: '${_formatearNumero(distanciaTotal)} km',
              icon: Icons.add_road,
              color: Colors.indigo[600]!,
              bgColor: Colors.indigo[50]!,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEficienciaCard(eficienciaKgKm),
      ],
    );
  }

  Widget _buildEficienciaCard(double eficienciaKgKm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eficiencia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatearNumero(eficienciaKgKm)} kg / km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kilos recolectados por kilómetro recorrido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRutasPorEstado() {
    final estados = (_reporte?['rutas_por_estado'] as Map<String, dynamic>?)
            ?.entries
            .toList() ??
        [];

    return _buildSeccionCard(
      titulo: 'Rutas por Estado',
      child: estados.isEmpty
          ? const Text('No hay datos de estados.')
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: estados.map((entry) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _colorEstado(entry.key).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _colorEstado(entry.key).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _colorEstado(entry.key),
                        ),
                      ),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRendimientoCamiones() {
    final camiones =
        (_reporte?['rendimiento_por_camion'] as List<dynamic>?) ?? [];

    return _buildSeccionCard(
      titulo: 'Rendimiento por Camión',
      child: camiones.isEmpty
          ? const Text('No hay datos de camiones para el período.')
          : Column(
              children: camiones.map((camion) {
                final patente = camion['patente']?.toString() ?? '-';
                final capacidad = camion['capacidad'] ?? 0.0;
                final kilos = camion['kilos_recogidos'] ?? 0.0;
                final rendimiento = camion['rendimiento'] ?? 0.0;
                final rutas = camion['rutas_asignadas'] ?? 0;

                return _buildListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.local_shipping,
                        color: Colors.blueAccent),
                  ),
                  title: patente,
                  subtitle:
                      'Capacidad: ${_formatearNumero(capacidad)} kg  •  $rutas rutas',
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatearNumero(kilos)} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Rendimiento: ${_formatearNumero(rendimiento)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEficienciaConductores() {
    final conductores =
        (_reporte?['eficiencia_por_conductor'] as List<dynamic>?) ?? [];

    return _buildSeccionCard(
      titulo: 'Eficiencia por Conductor',
      child: conductores.isEmpty
          ? const Text('No hay datos de conductores para el período.')
          : Column(
              children: conductores.map((conductor) {
                final email = conductor['chofer_email']?.toString() ?? '-';
                final rutas = conductor['rutas_realizadas'] ?? 0;
                final kilos = conductor['kilos_recogidos'] ?? 0.0;
                final promedio = conductor['peso_promedio_por_ruta'] ?? 0.0;

                return _buildListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: const Icon(Icons.person, color: Colors.green),
                  ),
                  title: email,
                  subtitle: '$rutas rutas',
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatearNumero(kilos)} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Prom: ${_formatearNumero(promedio)} kg/ruta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSeccionCard({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'finalizada':
        return Colors.green;
      case 'en curso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatearNumero(dynamic valor) {
    if (valor == null) return '0';
    final num? numero = num.tryParse(valor.toString());
    if (numero == null) return valor.toString();
    return numero.toStringAsFixed(numero.truncateToDouble() == numero ? 0 : 2);
  }
}
