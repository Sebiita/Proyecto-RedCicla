import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Servicio para gestionar las fichas de recolección.
///
/// Flujo de sincronización:
///
/// ┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
/// │ Usuario      │     │  SharedPrefs      │     │  FastAPI      │
/// │ llena ficha  │────►│  (persistente)    │────►│  → Firestore  │
/// └─────────────┘     └──────────────────┘     └──────────────┘
///       PASO 1              PASO 2                  PASO 3
///   crearFichaLocal()   Se guarda en disco    enviarFichaAlServidor()
///                       No se pierde si        o sincronizarPendientes()
///                       cierras la app
///
/// Las fichas pendientes se guardan en SharedPreferences como JSON.
/// Si cierras la app y la abres de nuevo, las fichas siguen ahí.
/// El SyncManager las envía automáticamente cuando detecta conexión.
class FichaService {
  // ============================================================
  // CLAVES DE SHARED PREFERENCES
  // ============================================================
  static const String _keyPendientes = 'fichas_pendientes';
  static const String _keySincronizadas = 'fichas_sincronizadas';

  // ============================================================
  // CACHE EN MEMORIA (se carga desde SharedPreferences al iniciar)
  // ============================================================
  static List<Map<String, dynamic>> _fichasPendientes = [];
  static List<Map<String, dynamic>> _fichasSincronizadas = [];
  static bool _inicializado = false;

  // ============================================================
  // INICIALIZACIÓN (Cargar fichas desde disco)
  // ============================================================

  /// Carga las fichas pendientes y sincronizadas desde SharedPreferences.
  /// Se debe llamar al iniciar la app (en main.dart).
  static Future<void> inicializar() async {
    if (_inicializado) return;

    final prefs = await SharedPreferences.getInstance();

    // Cargar fichas pendientes desde disco
    final pendientesJson = prefs.getString(_keyPendientes);
    if (pendientesJson != null) {
      final lista = jsonDecode(pendientesJson) as List;
      _fichasPendientes = lista.map((e) => Map<String, dynamic>.from(e)).toList();
      debugPrint('📂 ${_fichasPendientes.length} fichas pendientes cargadas desde disco');
    }

    // Cargar fichas sincronizadas desde disco
    final sincronizadasJson = prefs.getString(_keySincronizadas);
    if (sincronizadasJson != null) {
      final lista = jsonDecode(sincronizadasJson) as List;
      _fichasSincronizadas = lista.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    _inicializado = true;
  }

  /// Persiste las fichas pendientes en SharedPreferences.
  static Future<void> _guardarPendientesEnDisco() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendientes, jsonEncode(_fichasPendientes));
  }

  /// Persiste las fichas sincronizadas en SharedPreferences.
  static Future<void> _guardarSincronizadasEnDisco() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySincronizadas, jsonEncode(_fichasSincronizadas));
  }

  // ============================================================
  // CREAR FICHA LOCAL (El diccionario)
  // ============================================================

  /// Crea el diccionario de la ficha, lo almacena localmente Y en disco.
  /// Aunque cierres la app, la ficha no se pierde.
  static Future<Map<String, dynamic>> crearFichaLocal({
    required String rutaId,
    required String puntoId,
    required double kilosRecogidos,
    String observaciones = '',
    String fotoAntesUrl = '',
    String fotoDespuesUrl = '',
  }) async {
    final ficha = {
      'ruta_id': rutaId,
      'punto_id': puntoId,
      'kilos_recogidos': kilosRecogidos,
      'observaciones': observaciones,
      'foto_antes_url': fotoAntesUrl,
      'foto_despues_url': fotoDespuesUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Guardar en memoria
    _fichasPendientes.add(ficha);

    // Guardar en disco (persistente)
    await _guardarPendientesEnDisco();

    debugPrint('📋 Ficha guardada (memoria + disco). Pendientes: ${_fichasPendientes.length}');
    return ficha;
  }

  // ============================================================
  // ENVIAR FICHA AL SERVIDOR (Individual)
  // ============================================================

  /// Envía una ficha individual al servidor FastAPI.
  static Future<Map<String, dynamic>> enviarFichaAlServidor(
      Map<String, dynamic> ficha) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasRegistrar}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(ficha),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Mover de pendientes a sincronizadas
        _fichasPendientes.remove(ficha);
        _fichasSincronizadas.add({
          ...ficha,
          'id': responseData['ficha']?['id'] ?? '',
          'sincronizado': true,
        });

        // Persistir ambas listas en disco
        await _guardarPendientesEnDisco();
        await _guardarSincronizadasEnDisco();

        debugPrint('✅ Ficha enviada y persistida correctamente');
        return {'exito': true, 'datos': responseData};
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        return {'exito': false, 'error': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('📵 Sin conexión o error: $e');
      return {'exito': false, 'error': 'Sin conexión: $e'};
    }
  }

  // ============================================================
  // SINCRONIZAR BATCH (Todas las pendientes de una vez)
  // ============================================================

  /// Envía TODAS las fichas pendientes al servidor en un solo request.
  /// Este método es llamado automáticamente por el SyncManager
  /// cuando detecta que volvió la conexión a internet.
  static Future<Map<String, dynamic>> sincronizarFichasPendientes() async {
    if (_fichasPendientes.isEmpty) {
      debugPrint('ℹ️ No hay fichas pendientes por sincronizar');
      return {'exito': true, 'mensaje': 'No hay fichas pendientes'};
    }

    debugPrint('🔄 Sincronizando ${_fichasPendientes.length} fichas pendientes...');

    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasSincronizar}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fichas': _fichasPendientes}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Mover todas a sincronizadas
        for (var ficha in _fichasPendientes) {
          _fichasSincronizadas.add({
            ...ficha,
            'sincronizado': true,
          });
        }
        _fichasPendientes.clear();

        // Persistir en disco
        await _guardarPendientesEnDisco();
        await _guardarSincronizadasEnDisco();

        debugPrint('✅ ${responseData['total_sincronizadas']} fichas sincronizadas y persistidas');
        return {'exito': true, 'datos': responseData};
      } else {
        debugPrint('❌ Error al sincronizar: ${response.statusCode}');
        return {
          'exito': false,
          'error': 'Error del servidor: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('📵 Error de sincronización: $e');
      return {'exito': false, 'error': 'Sin conexión: $e'};
    }
  }

  // ============================================================
  // CONSULTAR FICHAS DESDE EL SERVIDOR
  // ============================================================

  /// Obtiene todas las fichas de una ruta desde el servidor.
  static Future<List<Map<String, dynamic>>> obtenerFichasPorRuta(
      String rutaId) async {
    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasPorRuta(rutaId)}');

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fichas = List<Map<String, dynamic>>.from(data['fichas'] ?? []);
        return fichas;
      }
    } catch (e) {
      debugPrint('Error al obtener fichas: $e');
    }
    return [];
  }

  // ============================================================
  // GETTERS
  // ============================================================

  static List<Map<String, dynamic>> get fichasPendientes =>
      List.unmodifiable(_fichasPendientes);

  static List<Map<String, dynamic>> get fichasSincronizadas =>
      List.unmodifiable(_fichasSincronizadas);

  static int get cantidadPendientes => _fichasPendientes.length;

  static bool get hayPendientes => _fichasPendientes.isNotEmpty;
}
