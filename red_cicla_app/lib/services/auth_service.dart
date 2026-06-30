import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Servicio centralizado de autenticación.
///
/// Responsabilidades:
/// - Realizar el login contra el backend FastAPI (que usa Argon2 para contraseñas)
/// - Mantener los datos del usuario en memoria durante la sesión
/// - Persistir la sesión en SharedPreferences cuando "Recordarme" está activo
/// - Proveer logout limpio
class AuthService {
  // ── Singleton de sesión en memoria ───────────────────────────
  static Map<String, dynamic>? _usuarioActual;

  /// Datos del usuario actualmente logueado. Null si no hay sesión.
  static Map<String, dynamic>? get usuarioActual => _usuarioActual;

  /// True si hay un usuario logueado en memoria.
  static bool get estaLogueado => _usuarioActual != null;

  // ── Claves para SharedPreferences ────────────────────────────
  static const String _keyUsuario = 'usuario_sesion';

  // ══════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════

  /// Inicia sesión llamando al endpoint POST /usuarios/login del backend.
  ///
  /// Retorna un mapa con:
  /// - 'exito': bool
  /// - 'usuario': Map si exito == true
  /// - 'error': String si exito == false
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
    bool recordarme = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuariosLogin}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo,
              'contraseña': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['usuario'] != null) {
        // Login exitoso
        _usuarioActual = Map<String, dynamic>.from(data['usuario']);
        debugPrint('✅ Login exitoso: ${_usuarioActual!['correo']}');

        // Persistir sesión si "Recordarme" está activo
        if (recordarme) {
          await _guardarSesion(_usuarioActual!);
        }

        return {'exito': true, 'usuario': _usuarioActual};
      } else {
        // El backend devolvió error (correo no encontrado, contraseña incorrecta)
        final mensaje = data['error'] ?? 'Error al iniciar sesión';
        debugPrint('❌ Login fallido: $mensaje');
        return {'exito': false, 'error': mensaje};
      }
    } on Exception catch (e) {
      debugPrint('📵 Error de conexión al hacer login: $e');
      return {
        'exito': false,
        'error': 'No se pudo conectar al servidor. Verifica que esté corriendo y que hayas ejecutado "adb reverse tcp:8000 tcp:8000".',
      };
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PERSISTENCIA DE SESIÓN
  // ══════════════════════════════════════════════════════════════

  /// Guarda los datos del usuario en SharedPreferences.
  static Future<void> _guardarSesion(Map<String, dynamic> usuario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsuario, jsonEncode(usuario));
      debugPrint('💾 Sesión guardada en disco');
    } catch (e) {
      debugPrint('⚠️ No se pudo guardar sesión: $e');
    }
  }

  /// Intenta cargar la sesión guardada en SharedPreferences.
  /// Retorna true si encontró una sesión válida.
  static Future<bool> cargarSesionGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesionJson = prefs.getString(_keyUsuario);
      if (sesionJson != null) {
        _usuarioActual = Map<String, dynamic>.from(jsonDecode(sesionJson));
        debugPrint('🔄 Sesión restaurada: ${_usuarioActual!['correo']}');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar sesión guardada: $e');
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════

  /// Cierra la sesión: borra datos en memoria y en SharedPreferences.
  static Future<void> cerrarSesion() async {
    _usuarioActual = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUsuario);
      debugPrint('👋 Sesión cerrada');
    } catch (e) {
      debugPrint('⚠️ Error al limpiar sesión guardada: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Nombre completo del usuario actual, o vacío si no hay sesión.
  static String get nombreCompleto {
    if (_usuarioActual == null) return '';
    final nombre = _usuarioActual!['nombre'] ?? '';
    final apellido = _usuarioActual!['apellido'] ?? '';
    return '$nombre $apellido'.trim();
  }

  /// Correo del usuario actual, o vacío si no hay sesión.
  static String get correo => _usuarioActual?['correo'] ?? '';

  /// Rol del usuario actual, o vacío si no hay sesión.
  static String get rol => _usuarioActual?['rol'] ?? '';
}
