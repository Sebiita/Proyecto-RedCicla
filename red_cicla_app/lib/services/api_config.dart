import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuración centralizada de la API del backend FastAPI.
/// Cambiar la URL base aquí para alternar entre desarrollo local y producción.
class ApiConfig {
  // ============================================================
  // DESARROLLO SIN USB (MISMA RED WI-FI):
  // 1. Inicia el servidor FastAPI en tu PC con:
  //    python -m uvicorn app:app --host 0.0.0.0 --port 8000
  // ============================================================

  /// URL base del servidor FastAPI. Se actualiza dinámicamente si se llama a descubrirServidor().
  static String baseUrl = 'http://172.26.13.210:8000';

  /// Descubre dinámicamente la IP del servidor en la red local.
  static Future<void> descubrirServidor() async {
    try {
      // 1. Verificar si hay alguna interfaz de red activa antes de intentar conectar.
      // Si el celular está completamente offline (sin Wi-Fi ni datos), salimos inmediatamente.
      final ipDispositivo = await _obtenerIpDispositivo();
      if (ipDispositivo == null) {
        debugPrint('📵 Dispositivo sin conexión de red activa. Omitiendo búsqueda de servidor.');
        return;
      }

      // Lista de URLs candidatas a probar primero.
      // ¡Tu equipo puede agregar sus propias IPs o nombres de red (.local) aquí!
      // Al compilar, la app probará todas en paralelo y se conectará al PC activo.
      final candidatos = [
        'http://192.168.43.6:8000',   // PC Cristian (Hotspot celular actual)
        'http://172.26.13.210:8000',  // PC Cristian (U. de Talca)
        'http://Cristian.local:8000', // PC Cristian (Nombre mDNS de Windows)
        'http://localhost:8000',       // Emuladores / Conexión USB
        'http://10.0.2.2:8000',        // Emulador Android estándar
        // --- AGREGA LAS IPs / NOMBRES DE PC DE TUS COLEGAS AQUÍ ABAJO: ---
        // 'http://192.168.1.X:8000',
        // 'http://NombreDeTuColega.local:8000',
      ];

      // 2. Probamos los candidatos rápidos en paralelo. Al ser solo unas pocas peticiones concurrentes,
      // no causamos saturación en la cola de sockets del celular.
      final resultados = await Future.wait(
        candidatos.map((url) => _probarServidor(url).then((activo) => activo ? url : null))
      );
      for (var res in resultados) {
        if (res != null) {
          baseUrl = res;
          debugPrint('📡 Conectado al servidor en: $baseUrl');
          return;
        }
      }

      // 3. Fallback: Si los candidatos rápidos fallan, realizamos un escaneo controlado
      // por lotes en la subred (muy útil para hotspots 192.168.x.x y redes 172.x.x.x).
      // Al usar lotes pequeños de 20 peticiones concurrentes, no se satura el event loop ni SharedPreferences.
      if (ipDispositivo.startsWith('192.168.') || ipDispositivo.startsWith('172.')) {
        final partes = ipDispositivo.split('.');
        final subred = '${partes[0]}.${partes[1]}.${partes[2]}';
        
        debugPrint('🔍 Iniciando escaneo seguro por lotes en subred $subred.X...');
        
        const loteSize = 20;
        for (var i = 1; i < 255; i += loteSize) {
          final end = (i + loteSize < 255) ? i + loteSize : 255;
          final lote = List.generate(end - i, (index) {
            final ipCandidata = '$subred.${i + index}';
            final urlCandidata = 'http://$ipCandidata:8000';
            return _probarServidor(urlCandidata).then((activo) => activo ? urlCandidata : null);
          });

          final respuestas = await Future.wait(lote);
          for (var res in respuestas) {
            if (res != null) {
              baseUrl = res;
              debugPrint('📡 Servidor descubierto en subred: $baseUrl');
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error durante el descubrimiento de servidor: $e');
    }

    debugPrint('📡 No se encontró backend activo dinámicamente, usando fallback: $baseUrl');
  }

  /// Prueba si el backend responde en una URL específica
  static Future<bool> _probarServidor(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Obtiene la IP local del dispositivo móvil
  static Future<String?> _obtenerIpDispositivo() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Endpoints de Fichas ──────────────────────────────────────
  static const String fichasRegistrar = '/fichas/registrar';
  static const String fichasSincronizar = '/fichas/sincronizar';
  static const String fichasListar = '/fichas/listar';
  static String fichasPorRuta(String rutaId) => '/fichas/por-ruta/$rutaId';
  static String fichasObtener(String fichaId) => '/fichas/obtener/$fichaId';

  // ── Endpoints de Rutas ───────────────────────────────────────
  static const String rutasListar = '/rutas/listar';
  static String rutasObtener(String rutaId) => '/rutas/obtener/$rutaId';

  // ── Endpoints de Puntos de Reciclaje ─────────────────────────
  /// Lista todos los puntos: GET /puntos/obtener
  static const String puntosListar = '/puntos/obtener';
  /// Obtiene un punto por ID: GET /puntos/obtener/{id}
  static String puntosObtener(String puntoId) => '/puntos/obtener/$puntoId';

  // ── Endpoints de Camiones ────────────────────────────────────
  /// Lista todos los camiones: GET /camiones/obtener
  static const String camionesListar = '/camiones/obtener';
  /// Obtiene un camión por patente: GET /camiones/obtener/{patente}
  static String camionesObtener(String patente) => '/camiones/obtener/$patente';

  // ── Endpoints de Reportes ────────────────────────────────────
  /// Reporte de rendimiento: GET /reportes/rendimiento
  static const String reportesRendimiento = '/reportes/rendimiento';

  // ── Endpoints de Usuarios ────────────────────────────────────
  /// Login: POST /usuarios/login
  static const String usuariosLogin = '/usuarios/login';
  /// Obtiene un usuario por correo: GET /usuarios/obtener/{correo}
  static String usuariosObtener(String correo) => '/usuarios/obtener/$correo';
}
