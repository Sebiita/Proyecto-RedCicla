/// Configuración centralizada de la API del backend FastAPI.
/// Cambiar la URL base aquí para alternar entre desarrollo local y producción.
class ApiConfig {
  // ============================================================
  // DESARROLLO LOCAL CON CELULAR FÍSICO VÍA USB:
  // Antes de correr la app, ejecuta en la terminal del PC:
  //   adb reverse tcp:8000 tcp:8000
  // Eso redirige el localhost:8000 del celular al servidor del PC.
  //
  // Para emulador Android usa: http://10.0.2.2:8000
  // ============================================================

  /// URL base del servidor FastAPI
  static const String baseUrl = 'http://localhost:8000';

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

  // ── Endpoints de Usuarios ────────────────────────────────────
  /// Login: POST /usuarios/login
  static const String usuariosLogin = '/usuarios/login';
  /// Obtiene un usuario por correo: GET /usuarios/obtener/{correo}
  static String usuariosObtener(String correo) => '/usuarios/obtener/$correo';
}
