import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ficha_service.dart';

/// Gestor de sincronización automática.
///
/// Escucha cambios en la conexión a internet y cuando detecta
/// que volvió la señal, envía automáticamente todas las fichas
/// pendientes al servidor.
///
/// Diagrama de funcionamiento:
///
///   App se inicia
///       │
///       ▼
///   SyncManager.iniciar()
///       │
///       ├── Escucha cambios de red (WiFi/Datos/Ninguno)
///       │
///       ▼
///   ¿Cambió a CONECTADO?
///       │
///       ├── Sí ──► ¿Hay fichas pendientes?
///       │              │
///       │              ├── Sí ──► FichaService.sincronizarFichasPendientes()
///       │              │              │
///       │              │              └── POST /fichas/sincronizar (batch)
///       │              │
///       │              └── No ──► (nada que hacer)
///       │
///       └── No ──► (seguir escuchando)
///
class SyncManager {
  static StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  static bool _sincronizando = false;

  /// Inicia el listener de conectividad.
  /// Llamar una sola vez desde main.dart
  static void iniciar() {
    // Cancelar suscripción anterior si existe
    _suscripcion?.cancel();

    _suscripcion = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> resultados) {
        // Verificar si hay alguna conexión activa
        final hayConexion = resultados.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet);

        if (hayConexion) {
          debugPrint('🌐 Conexión detectada. Verificando fichas pendientes...');
          _intentarSincronizar();
        } else {
          debugPrint('📵 Sin conexión. Las fichas se guardarán localmente.');
        }
      },
    );

    debugPrint('🔄 SyncManager iniciado - escuchando cambios de red');

    // También intentar sincronizar al iniciar (por si hay pendientes del uso anterior)
    _intentarSincronizar();
  }

  /// Intenta sincronizar las fichas pendientes.
  /// Evita múltiples sincronizaciones simultáneas.
  static Future<void> _intentarSincronizar() async {
    // Evitar sincronizaciones simultáneas
    if (_sincronizando) {
      debugPrint('⏳ Ya hay una sincronización en curso, esperando...');
      return;
    }

    if (!FichaService.hayPendientes) {
      return;
    }

    _sincronizando = true;

    try {
      debugPrint('🔄 Sincronizando ${FichaService.cantidadPendientes} fichas...');
      final resultado = await FichaService.sincronizarFichasPendientes();

      if (resultado['exito'] == true) {
        debugPrint('✅ Sincronización automática exitosa');
      } else {
        debugPrint('❌ Sincronización falló: ${resultado['error']}');
      }
    } catch (e) {
      debugPrint('❌ Error en sincronización automática: $e');
    } finally {
      _sincronizando = false;
    }
  }

  /// Fuerza una sincronización manual (por ejemplo desde un botón).
  static Future<Map<String, dynamic>> forzarSincronizacion() async {
    if (!FichaService.hayPendientes) {
      return {'exito': true, 'mensaje': 'No hay fichas pendientes'};
    }

    _sincronizando = true;
    try {
      return await FichaService.sincronizarFichasPendientes();
    } finally {
      _sincronizando = false;
    }
  }

  /// Detiene el listener de conectividad.
  static void detener() {
    _suscripcion?.cancel();
    _suscripcion = null;
    debugPrint('🛑 SyncManager detenido');
  }

  /// True si hay una sincronización en progreso.
  static bool get sincronizando => _sincronizando;
}
