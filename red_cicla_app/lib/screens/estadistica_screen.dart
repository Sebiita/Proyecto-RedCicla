import 'package:flutter/material.dart';

class EstadisticaScreen extends StatelessWidget {
  // Parámetros de entrada de la pantalla para que sea totalmente dinámica y conectable más adelante.
  final String nombreUsuario;
  final String rutUsuario;
  final String patenteCamion;
  final String modeloCamion;
  final double kilosRecogidos;
  final int puntosTotales;
  final int puntosCompletados;
  final int puntosNoCompletados;
  final String fechaRuta;

  const EstadisticaScreen({
    super.key,
    this.nombreUsuario = 'Pedro Sanhueza',
    this.rutUsuario = '12.345.678-9',
    this.patenteCamion = 'AB-CD-12',
    this.modeloCamion = 'Mercedes-Benz Atego',
    this.kilosRecogidos = 185.5,
    this.puntosTotales = 5,
    this.puntosCompletados = 4,
    this.puntosNoCompletados = 1,
    this.fechaRuta = 'Jueves, 18 de Junio de 2026',
  });

  @override
  Widget build(BuildContext context) {
    // Porcentaje de completitud para el gráfico circular
    final double porcentajeCompletado = puntosTotales > 0 
        ? (puntosCompletados / puntosTotales) 
        : 0.0;
    
    final int porcentajeTexto = (porcentajeCompletado * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Gris suave premium para fondo
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FECHA DE LA JORNADA
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    fechaRuta,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. TARJETA DEL USUARIO Y CAMIÓN
              _buildUsuarioCamionCard(),

              const SizedBox(height: 24),

              // Título de la sección de estadísticas
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

              // 3. SECCIÓN DE AVANCE CIRCULAR (GORGEOUS RADIAL SUMMARY CARD)
              _buildProgressCard(porcentajeCompletado, porcentajeTexto),

              const SizedBox(height: 16),

              // 4. GRILLA DE MÉTRICAS (KILOS, TOTALES, COMPLETADOS, PENDIENTES)
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
                    value: '${kilosRecogidos.toStringAsFixed(1)} Kg',
                    icon: Icons.scale_outlined,
                    color: Colors.green[600]!,
                    bgColor: Colors.green[50]!,
                  ),
                  _buildMetricCard(
                    title: 'Puntos Totales',
                    value: '$puntosTotales',
                    icon: Icons.map_outlined,
                    color: Colors.blue[600]!,
                    bgColor: Colors.blue[50]!,
                  ),
                  _buildMetricCard(
                    title: 'Puntos Completados',
                    value: '$puntosCompletados',
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

  // Widget: Tarjeta elegante con datos del Usuario y el Camión
  Widget _buildUsuarioCamionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Franja superior verde decorativa
            Container(
              height: 6,
              color: Colors.green,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Fila de Operador
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[50],
                        child: const Icon(
                          Icons.person,
                          color: Colors.green,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreUsuario,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RUT: $rutUsuario',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Operador',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  // Fila de Camión
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue[50],
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patenteCamion,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              modeloCamion,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Vehículo',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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

  // Widget: Tarjeta del progreso circular de la jornada
  Widget _buildProgressCard(double porcentajeCompletado, int porcentajeTexto) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Gráfico circular
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Resumen verbal
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
                  porcentajeCompletado == 1.0
                      ? '¡Excelente trabajo! Has completado todos los puntos asignados para hoy.'
                      : 'Llevas un buen ritmo. Te quedan $puntosNoCompletados de los $puntosTotales puntos asignados en tu ruta.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Tarjetas individuales de estadísticas
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
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
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
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
