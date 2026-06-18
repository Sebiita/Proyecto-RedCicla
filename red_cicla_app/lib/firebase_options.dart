import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Si estás corriendo la app en Android (emulador o celular)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDzVLUKt-1f2aLC-gLQ_LBV0qzEWU7fhMg',
        appId: '1:573203781096:android:b7cd6d40c4916aa4b6805d',
        messagingSenderId: '573203781096',
        projectId: 'proyecto-redcicla',
        storageBucket: 'proyecto-redcicla.firebasestorage.app', // (Generalmente es tu proyecto + .firebasestorage.app)
      );
    }
    // Agrega condicionales para iOS si en el futuro ocupan iPhones.
    throw UnsupportedError('La plataforma actual no está soportada a mano.');
  }
}