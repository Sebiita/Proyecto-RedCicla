import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Servicio para obtener las rutas asignadas desde el backend FastAPI.
///
/// Las rutas vienen con sus puntos y la app los muestra en HomeScreen.
class RutaService {
  /// Obtiene todas las rutas desde el servidor.
  /// Endpoint: GET /rutas/listar
  static Future<List<Map<String, dynamic>>> obtenerTodasLasRutas() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rutasListar}');
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rutas = List<Map<String, dynamic>>.from(data['rutas'] ?? []);
        debugPrint('✅ ${rutas.length} rutas obtenidas del servidor');
        return rutas;
      } else {
        debugPrint('❌ Error al obtener rutas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al obtener rutas: $e');
      return [];
    }
  }

  /// Obtiene una ruta específica por ID desde el servidor.
  /// Endpoint: GET /rutas/obtener/{id}
  static Future<Map<String, dynamic>?> obtenerRuta(String rutaId) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.rutasObtener(rutaId)}');
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['ruta'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error al obtener ruta: $e');
    }
    return null;
  }

  /// Busca la ruta asignada a un usuario (como chofer o ayudante) para la fecha
  /// de hoy. Retorna la primera ruta encontrada o null si no hay ninguna.
  ///
  /// El backend guarda el correo del usuario en los campos:
  /// 'chofer_asignado' y 'ayudante_asignado'.
  static Future<Map<String, dynamic>?> obtenerRutaDelUsuario(
      String correoUsuario) async {
    try {
      final rutas = await obtenerTodasLasRutas();
      if (rutas.isEmpty) return null;

      final hoy = DateTime.now();
      // Formato de fecha ISO que usa el backend: "YYYY-MM-DD"
      final hoyStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      // Buscar ruta de hoy asignada al usuario
      for (final ruta in rutas) {
        final fecha = ruta['fecha']?.toString() ?? '';
        final chofer = ruta['chofer_asignado']?.toString() ?? '';
        final ayudante = ruta['ayudante_asignado']?.toString() ?? '';

        final esDeHoy = fecha.startsWith(hoyStr);
        final esDelUsuario =
            chofer == correoUsuario || ayudante == correoUsuario;

        if (esDeHoy && esDelUsuario) {
          debugPrint('✅ Ruta de hoy encontrada para $correoUsuario: ${ruta['id']}');
          return ruta;
        }
      }

      // Si no hay ruta de hoy, retornar la más reciente del usuario
      final rutasDelUsuario = rutas.where((r) {
        final chofer = r['chofer_asignado']?.toString() ?? '';
        final ayudante = r['ayudante_asignado']?.toString() ?? '';
        return chofer == correoUsuario || ayudante == correoUsuario;
      }).toList();

      if (rutasDelUsuario.isNotEmpty) {
        debugPrint(
            '⚠️ No hay ruta de hoy para $correoUsuario. Mostrando la más reciente.');
        return rutasDelUsuario.last;
      }

      debugPrint('⚠️ No se encontró ninguna ruta para $correoUsuario');
      return null;
    } catch (e) {
      debugPrint('📵 Error al obtener ruta del usuario: $e');
      return null;
    }
  }
}
