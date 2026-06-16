import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Servicio para obtener las rutas asignadas desde el backend FastAPI.
///
/// Las rutas vienen con sus puntos y la app los muestra en HomeScreen.
class RutaService {
  /// Obtiene todas las rutas desde el servidor.
  /// Retorna una lista de diccionarios con los datos de cada ruta.
  static Future<List<Map<String, dynamic>>> obtenerTodasLasRutas() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rutasListar}');

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
  static Future<Map<String, dynamic>?> obtenerRuta(String rutaId) async {
    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rutasObtener(rutaId)}');

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ruta'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error al obtener ruta: $e');
    }
    return null;
  }
}
