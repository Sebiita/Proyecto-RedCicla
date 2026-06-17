import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar las fichas de recolección automatizado con FIREBASE.
///
/// Flujo de sincronización nativo de Firebase:
/// 1. creamos el documento offline
/// 2. Firebase lo guarda en caché interno (¡Magia! sin SharedPreferences manual)
/// 3. Firebase está atento y tan pronto detecta internet lo sincroniza a Cloud Firestore.
class FichaService {
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    // Si necesitas inicializar otras configuraciones futuras.
    // Para Firebase, la inicialización ya se hizo en main.dart
    _inicializado = true;
    debugPrint("Servicio de fichas con Firebase listo ?");
  }

  // ============================================================
  // CREAR FICHA (Nativo con Firebase Cloud Firestore)
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
      'timestamp': FieldValue.serverTimestamp(), // Marca de tiempo oficial
    };

    try {
      // Firebase automáticamente decide:
      // ¿Hay internet? -> Lo envía a la nube.
      // ¿NO hay internet? -> Lo guarda en caché duro y lo envía mágicamente después.
      await FirebaseFirestore.instance.collection('fichas').add(ficha);
      debugPrint('?? Ficha encolada en Firestore exitosamente');
    } catch (e) {
      debugPrint('? Error al encolar en Firestore: $e');
    }

    return ficha;
  }

  // ============================================================
  // CONSULTAR FICHAS DESDE FIREBASE
  // ============================================================
  static Future<List<Map<String, dynamic>>> obtenerFichasPorRuta(String rutaId) async {
    try {
      // Obtener desde Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('fichas')
          .where('ruta_id', isEqualTo: rutaId)
          .get();

      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener fichas de Firestore: $e');
      return [];
    }
  }

  // Estos métodos/getters se pueden remover pues Firebase maneja esto
  static int get cantidadPendientes => 0; // Ya no hay manejo manual
  static bool get hayPendientes => false; // Ya no hay manejo manual
}
