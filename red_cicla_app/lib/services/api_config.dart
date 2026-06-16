/// Configuración centralizada de la API del backend FastAPI.
/// Cambiar la URL base aquí para alternar entre desarrollo local y producción.
class ApiConfig {
  // ============================================================
  // DESARROLLO LOCAL:
  // - Android Emulator: usa 10.0.2.2 (alias del host)
  // - iOS Simulator / dispositivo real en la misma red: usa la IP local
  // - Web: usa localhost
  // ============================================================

  /// URL base del servidor FastAPI
  /// Para desarrollo local con dispositivo físico, cambia a tu IP local:
  /// Ejemplo: 'http://192.168.1.100:8000'
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Endpoints de fichas
  static const String fichasRegistrar = '/fichas/registrar';
  static const String fichasSincronizar = '/fichas/sincronizar';
  static const String fichasListar = '/fichas/listar';
  static String fichasPorRuta(String rutaId) => '/fichas/por-ruta/$rutaId';
  static String fichasObtener(String fichaId) => '/fichas/obtener/$fichaId';

  // Endpoints de rutas
  static const String rutasListar = '/rutas/listar';
  static String rutasObtener(String rutaId) => '/rutas/obtener/$rutaId';

  // Endpoints de login
  static const String usuariosLogin = '/usuarios/login';
}
