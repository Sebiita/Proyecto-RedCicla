import 'package:flutter/material.dart';
import '../services/ficha_service.dart';

class EstadisticaScreen extends StatefulWidget {
  final String rutaId;
  final String nombreUsuario;
  final String patenteCamion;
  final String modeloCamion;
  final int puntosTotales;
  final String fechaRuta;

  const EstadisticaScreen({
    super.key,
    required this.rutaId,
    required this.nombreUsuario,
    required this.patenteCamion,
    required this.modeloCamion,
    required this.puntosTotales,
    required this.fechaRuta,
  });

  @override
  State<EstadisticaScreen> createState() => _EstadisticaScreenState();
}

class _EstadisticaScreenState extends State<EstadisticaScreen> {
  // ── Estado de carga ──────────────────────────────────────────
  bool _cargando = true;

  // ── Datos calculados desde Firestore ─────────────────────────
  double _kilosRecogidos = 0.0;
  int _puntosCompletados = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  /// Carga las fichas del ruta actual desde Firestore y calcula estadísticas.
  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);

    try {
      // Las fichas se leen directo desde Firestore (sync offline/online)
      final fichas =
          await FichaService.obtenerFichasPorRuta(widget.rutaId);

      double kilosTotales = 0.0;
      for (final ficha in fichas) {
        final kilos = (ficha['kilos_recogidos'] as num?)?.toDouble() ?? 0.0;
        kilosTotales += kilos;
      }

      if (!mounted) return;
      setState(() {
        _kilosRecogidos = kilosTotales;
        _puntosCompletados = fichas.length;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntosNoCompletados =
        (widget.puntosTotales - _puntosCompletados).clamp(0, widget.puntosTotales);
    final double porcentajeCompletado = widget.puntosTotales > 0
        ? (_puntosCompletados / widget.puntosTotales).clamp(0.0, 1.0)
        : 0.0;
    final int porcentajeTexto = (porcentajeCompletado * 100).toInt();

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
          'Resumen de Jornada',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Botón de recarga
          if (!_cargando)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _cargarEstadisticas,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Calculando estadísticas...'),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. FECHA DE LA JORNADA
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.fechaRuta.isNotEmpty
                              ? widget.fechaRuta
                              : 'Hoy',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. TARJETA USUARIO Y CAMIÓN
                    _buildUsuarioCamionCard(),
                    const SizedBox(height: 24),

                    const Text(
                      'MÉTRICAS DE HOY',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. PROGRESO CIRCULAR
                    _buildProgressCard(porcentajeCompletado, porcentajeTexto,
                        puntosNoCompletados),
                    const SizedBox(height: 16),

                    // 4. GRILLA DE MÉTRICAS
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildMetricCard(
                          title: 'Vidrio Recogido',
                          value: '${_kilosRecogidos.toStringAsFixed(1)} Kg',
                          icon: Icons.scale_outlined,
                          color: Colors.green[600]!,
                          bgColor: Colors.green[50]!,
                        ),
                        _buildMetricCard(
                          title: 'Puntos Totales',
                          value: '${widget.puntosTotales}',
                          icon: Icons.map_outlined,
                          color: Colors.blue[600]!,
                          bgColor: Colors.blue[50]!,
                        ),
                        _buildMetricCard(
                          title: 'Puntos Completados',
                          value: '$_puntosCompletados',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.teal[600]!,
                          bgColor: Colors.teal[50]!,
                        ),
                        _buildMetricCard(
                          title: 'Puntos Pendientes',
                          value: '$puntosNoCompletados',
                          icon: Icons.pending_actions_rounded,
                          color: Colors.orange[800]!,
                          bgColor: Colors.orange[50]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUsuarioCamionCard() {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(height: 6, color: Colors.green),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Fila operador
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[50],
                        child: const Icon(Icons.person,
                            color: Colors.green, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombreUsuario.isNotEmpty
                                  ? widget.nombreUsuario
                                  : 'Usuario',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Operador',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: Colors.grey[200]),
                  ),
                  // Fila camión
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue[50],
                        child: const Icon(Icons.local_shipping_outlined,
                            color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patenteCamion.isNotEmpty
                                  ? widget.patenteCamion
                                  : 'Sin camión',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            if (widget.modeloCamion.isNotEmpty)
                              Text(
                                widget.modeloCamion,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Vehículo',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      double porcentajeCompletado, int porcentajeTexto, int pendientes) {
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
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: porcentajeCompletado,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$porcentajeTexto%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Listo',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progreso General',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  porcentajeCompletado >= 1.0
                      ? '¡Excelente trabajo! Has completado todos los puntos asignados para hoy.'
                      : 'Llevas un buen ritmo. Te quedan $pendientes de los ${widget.puntosTotales} puntos asignados.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.3),
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
          Row(
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
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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
}
