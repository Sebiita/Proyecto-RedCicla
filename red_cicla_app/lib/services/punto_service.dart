import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Servicio para consultar puntos de reciclaje desde el backend FastAPI.
class PuntoService {
  /// Obtiene todos los puntos de reciclaje.
  /// Endpoint: GET /puntos/obtener
  static Future<List<Map<String, dynamic>>> obtenerTodosLosPuntos() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.puntosListar}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final puntos = List<Map<String, dynamic>>.from(data['puntos'] ?? []);
        debugPrint('✅ ${puntos.length} puntos obtenidos del backend');
        return puntos;
      } else {
        debugPrint('❌ Error al listar puntos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al listar puntos: $e');
      return [];
    }
  }

  /// Obtiene un punto de reciclaje específico por su ID de Firestore.
  /// Endpoint: GET /puntos/obtener/{id}
  static Future<Map<String, dynamic>?> obtenerPunto(String puntoId) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.puntosObtener(puntoId)}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['punto'] as Map<String, dynamic>?;
      } else {
        debugPrint('❌ Error al obtener punto $puntoId: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al obtener punto $puntoId: $e');
      return null;
    }
  }

  /// Obtiene múltiples puntos a partir de una lista de IDs.
  /// Útil para cargar todos los puntos de una ruta.
  static Future<List<Map<String, dynamic>>> obtenerPuntosPorIds(
      List<dynamic> puntosIds) async {
    if (puntosIds.isEmpty) return [];

    // Obtenemos todos los puntos y filtramos por los IDs que necesitamos.
    // Si hay muchos puntos en la DB, se puede optimizar con llamadas individuales.
    try {
      final todosPuntos = await obtenerTodosLosPuntos();
      final ids = puntosIds.map((e) => e.toString()).toSet();
      return todosPuntos
          .where((p) => ids.contains(p['id']?.toString()))
          .toList();
    } catch (e) {
      debugPrint('📵 Error al obtener puntos por IDs: $e');
      return [];
    }
  }
}
