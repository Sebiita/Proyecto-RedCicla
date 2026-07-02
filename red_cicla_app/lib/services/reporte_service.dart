import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Servicio para obtener el reporte de rendimiento desde el backend FastAPI.
///
/// Endpoint: GET /reportes/rendimiento
class ReporteService {
  /// Obtiene el reporte de rendimiento con filtros opcionales.
  ///
  /// Parámetros:
  /// - [fechaInicio]: fecha de inicio del período (YYYY-MM-DD).
  /// - [fechaFin]: fecha de término del período (YYYY-MM-DD).
  /// - [camionAsignado]: patente del camión para filtrar.
  /// - [choferAsignado]: correo del chofer para filtrar.
  ///
  /// Retorna un [Map<String, dynamic>] con el reporte o null si hay error.
  static Future<Map<String, dynamic>?> obtenerReporteRendimiento({
    String? fechaInicio,
    String? fechaFin,
    String? camionAsignado,
    String? choferAsignado,
  }) async {
    try {
      final params = <String, String>{};
      if (fechaInicio != null && fechaInicio.isNotEmpty) {
        params['fecha_inicio'] = fechaInicio;
      }
      if (fechaFin != null && fechaFin.isNotEmpty) {
        params['fecha_fin'] = fechaFin;
      }
      if (camionAsignado != null && camionAsignado.isNotEmpty) {
        params['camion_asignado'] = camionAsignado;
      }
      if (choferAsignado != null && choferAsignado.isNotEmpty) {
        params['chofer_asignado'] = choferAsignado;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.reportesRendimiento}',
      ).replace(queryParameters: params.isNotEmpty ? params : null);

      debugPrint('📊 Consultando reporte: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        debugPrint('✅ Reporte de rendimiento obtenido');
        return data;
      } else {
        debugPrint('❌ Error al obtener reporte: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('📵 Error de conexión al obtener reporte: $e');
      return null;
    }
  }
}
