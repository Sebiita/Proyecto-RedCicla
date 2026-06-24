import 'package:flutter/material.dart';
import '../services/ruta_service.dart';
import '../services/punto_service.dart';
import '../services/camion_service.dart';
import '../services/auth_service.dart';
import '../services/ficha_service.dart';
import 'ficha_screen.dart';
import 'estadistica_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Datos del usuario logueado, recibidos desde LoginScreen.
  final Map<String, dynamic> usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Estado de carga ──────────────────────────────────────────
  bool _cargando = true;
  String? _errorCarga;

  // ── Datos reales desde el backend ───────────────────────────
  Map<String, dynamic>? _ruta;
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _camion;

  // ── Navegación del BottomNavigationBar ───────────────────────
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Carga de datos ───────────────────────────────────────────
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final correo = widget.usuario['correo']?.toString() ?? '';

      // 1. Obtener la ruta asignada al usuario de hoy
      final ruta = await RutaService.obtenerRutaDelUsuario(correo);
      if (!mounted) return;

      if (ruta == null) {
        setState(() {
          _cargando = false;
          _errorCarga = 'No tienes una ruta asignada para hoy.';
        });
        return;
      }

      // 2. Obtener los puntos de esa ruta desde el backend
      final puntosIds = List<dynamic>.from(ruta['puntos'] ?? []);
      final puntos = await PuntoService.obtenerPuntosPorIds(puntosIds);
      if (!mounted) return;

      // 3. Obtener datos del camión asignado a la ruta
      final patenteCamion = ruta['camion_asignado']?.toString() ?? '';
      Map<String, dynamic>? camion;
      if (patenteCamion.isNotEmpty) {
        camion = await CamionService.obtenerCamion(patenteCamion);
      }
      if (!mounted) return;

      setState(() {
        _ruta = ruta;
        _puntos = puntos;
        _camion = camion;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'Error al cargar datos: $e';
      });
    }
  }

  // ── Cerrar sesión ─────────────────────────────────────────────
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await AuthService.cerrarSesion();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ── Helpers de UI ─────────────────────────────────────────────
  String get _nombreUsuario {
    final nombre = widget.usuario['nombre']?.toString() ?? '';
    final apellido = widget.usuario['apellido']?.toString() ?? '';
    return '$nombre $apellido'.trim();
  }

  String get _nombreCortoAyudante {
    // El ayudante es el otro campo de la ruta (no el usuario actual)
    final correoUsuario = widget.usuario['correo']?.toString() ?? '';
    final chofer = _ruta?['chofer_asignado']?.toString() ?? '';
    final ayudante = _ruta?['ayudante_asignado']?.toString() ?? '';

    // Si el usuario es el chofer, mostramos el correo del ayudante y viceversa
    final otroCorreo = correoUsuario == chofer ? ayudante : chofer;
    if (otroCorreo.isEmpty) return 'Sin asignar';
    // Mostrar solo la parte antes del @
    return otroCorreo.split('@').first;
  }

  String get _patenteCamion =>
      _ruta?['camion_asignado']?.toString() ?? 'Sin camión';

  String get _estadoRuta => _ruta?['estado']?.toString() ?? 'Pendiente';

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,

      // ── FAB Mapa ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mapa próximamente disponible')),
          );
        },
        backgroundColor: Colors.blue[600],
        shape: const CircleBorder(),
        child: const Icon(Icons.map, color: Colors.white),
      ),

      // ── BottomNavigationBar ───────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabActual,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1 && _ruta != null) {
            // Tab Estadísticas
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EstadisticaScreen(
                  rutaId: _ruta!['id']?.toString() ?? '',
                  nombreUsuario: _nombreUsuario,
                  patenteCamion: _patenteCamion,
                  modeloCamion: _camion?['modelo']?.toString() ??
                      _camion?['patente']?.toString() ?? 'Sin datos',
                  puntosTotales: _puntos.length,
                  fechaRuta: _ruta?['fecha']?.toString() ?? '',
                ),
              ),
            );
          } else if (index == 2) {
            // Tab Perfil / Cerrar sesión
            _cerrarSesion();
          } else {
            setState(() => _tabActual = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Salir',
          ),
        ],
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado verde ─────────────────────────────
            Container(
              height: altoPantalla * 0.18,
              width: double.infinity,
              color: Colors.green,
              padding:
                  const EdgeInsets.only(top: 20, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _cargando
                              ? 'Cargando ruta...'
                              : (_ruta != null
                                  ? 'Ruta: ${_ruta!['fecha'] ?? 'Hoy'}'
                                  : 'Sin ruta asignada'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Botón Sincronizar Fichas
                      if (!_cargando)
                         IconButton(
                           icon: const Icon(Icons.sync, color: Colors.white),
                           tooltip: 'Sincronizar pendientes',
                           onPressed: () async {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizando...')));
                             final success = await FichaService.sincronizarPendientes();
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(success ? '✅ Fichas sincronizadas' : '❌ Error de sincronización'),
                                   backgroundColor: success ? Colors.green : Colors.red,
                                 ),
                               );
                             }
                           },
                         ),
                      // Badge de estado
                      if (!_cargando && _ruta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green[200]!, width: 1),
                          ),
                          child: Text(
                            _estadoRuta.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cargando
                        ? '...'
                        : 'Camión: $_patenteCamion  |  Compañero: $_nombreCortoAyudante',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Operador: $_nombreUsuario',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Cuerpo ───────────────────────────────────────
            Expanded(child: _buildCuerpo()),
          ],
        ),
      ),
    );
  }

  Widget _buildCuerpo() {
    // Estado de carga
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Cargando datos de la ruta...'),
          ],
        ),
      );
    }

    // Error o sin ruta
    if (_errorCarga != null || _ruta == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorCarga ?? 'No hay ruta disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Lista de puntos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: 20, left: 24, right: 24, bottom: 10),
          child: Text(
            'PUNTOS DE HOY (${_puntos.length})',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: _puntos.isEmpty
              ? Center(
                  child: Text(
                    'No hay puntos cargados para esta ruta.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _puntos.length,
                  itemBuilder: (context, index) {
                    final punto = _puntos[index];
                    final puntoId = punto['id']?.toString() ?? 'punto_$index';
                    final nombrePunto =
                        punto['municipalidad']?.toString() ?? 'Punto ${index + 1}';
                    final urgencia = punto['urgencia']?.toString() ?? 'Normal';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FichaScreen(
                              rutaId: _ruta!['id']?.toString() ?? '',
                              puntoId: puntoId,
                              nombrePunto: nombrePunto,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _colorUrgencia(urgencia),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ícono con color de urgencia
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    _colorUrgencia(urgencia).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: _colorUrgencia(urgencia),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombrePunto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _colorUrgencia(urgencia)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          urgencia,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _colorUrgencia(urgencia),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${punto['capacidad_ocupada'] ?? 0}/${punto['capacidad_maxima'] ?? 0} kg',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Retorna el color según el nivel de urgencia del punto.
  Color _colorUrgencia(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'crítica':
      case 'critica':
        return Colors.red[600]!;
      case 'alta':
        return Colors.orange[700]!;
      case 'normal':
        return Colors.green[600]!;
      case 'baja':
        return Colors.blue[400]!;
      default:
        return Colors.green[400]!;
    }
  }
}
