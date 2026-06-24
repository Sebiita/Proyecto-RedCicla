import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Servicio para consultar camiones desde el backend FastAPI.
class CamionService {
  /// Obtiene un camión específico por su patente.
  /// Endpoint: GET /camiones/obtener/{patente}
  static Future<Map<String, dynamic>?> obtenerCamion(String patente) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.camionesObtener(patente)}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['camion'] as Map<String, dynamic>?;
      } else {
        debugPrint(
            '❌ Error al obtener camión $patente: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al obtener camión $patente: $e');
      return null;
    }
  }

  /// Obtiene todos los camiones registrados.
  /// Endpoint: GET /camiones/obtener
  static Future<List<Map<String, dynamic>>> obtenerTodosLosCamiones() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.camionesListar}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data['camiones'] ?? []);
      } else {
        debugPrint('❌ Error al listar camiones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al listar camiones: $e');
      return [];
    }
  }
}
