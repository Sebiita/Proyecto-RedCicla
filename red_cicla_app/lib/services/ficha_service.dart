import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Servicio para gestionar las fichas de recolección conectándose al backend FastAPI.
///
/// Flujo de sincronización local:
/// 1. Intentamos enviar al backend.
/// 2. Si no hay conexión o da error, se guarda localmente (SharedPreferences).
/// 3. Se puede llamar a `sincronizarPendientes()` luego para vaciar la cola.
class FichaService {
  static const String _pendientesKey = 'fichas_pendientes';

  // ============================================================
  // CREAR FICHA (Intenta backend, si falla guarda offline)
  // ============================================================
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
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasRegistrar}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ficha),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Ficha enviada al servidor exitosamente');
        return ficha;
      } else {
        debugPrint('❌ Servidor respondió con error: ${response.body}');
        await _guardarFichaPendiente(ficha);
      }
    } catch (e) {
      debugPrint('📵 Sin conexión al servidor, guardando ficha offline: $e');
      await _guardarFichaPendiente(ficha);
    }

    return ficha;
  }

  // ============================================================
  // OBTENER FICHAS DE UNA RUTA DESDE EL BACKEND
  // ============================================================
  static Future<List<Map<String, dynamic>>> obtenerFichasPorRuta(String rutaId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasPorRuta(rutaId)}');
      final response = await http.get(url).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Dependiendo de cómo responde tu backend, extraemos la lista
        if (data.containsKey('fichas')) {
           return List<Map<String, dynamic>>.from(data['fichas']);
        }
        return [];
      } else {
        debugPrint('❌ Error al obtener fichas por ruta: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('📵 Error conectando al servidor para obtener fichas: $e');
      return [];
    }
  }

  // ============================================================
  // LÓGICA OFFLINE (Sincronización manual/automática)
  // ============================================================
  static Future<void> _guardarFichaPendiente(Map<String, dynamic> ficha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendientesJson = prefs.getStringList(_pendientesKey) ?? [];
      pendientesJson.add(jsonEncode(ficha));
      await prefs.setStringList(_pendientesKey, pendientesJson);
      debugPrint('✅ Ficha guardada en caché local correctamente');
    } catch (e) {
      debugPrint('❌ Error crítico al guardar en caché local: $e');
      throw Exception('No se pudo guardar la ficha offline.');
    }
  }

  static Future<int> getCantidadPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendientesKey) ?? []).length;
  }

  static Future<bool> sincronizarPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final pendientesJson = prefs.getStringList(_pendientesKey) ?? [];

    if (pendientesJson.isEmpty) return true;

    final fichas = pendientesJson.map((e) => jsonDecode(e)).toList();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fichasSincronizar}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fichas': fichas}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Fichas pendientes sincronizadas exitosamente');
        await prefs.remove(_pendientesKey);
        return true;
      } else {
        debugPrint('❌ Error al sincronizar fichas: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('📵 Sin conexión al sincronizar fichas: $e');
      return false;
    }
  }
}
