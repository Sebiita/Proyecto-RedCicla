import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Descubrir backend en la red local en segundo plano (no bloquea el inicio de la app)
  ApiConfig.descubrirServidor();

  // Inicializar Firebase (necesario para Firestore — sync de fichas)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase listo ✅');
  } catch (e) {
    debugPrint('-------------------------------------------------');
    debugPrint('⚠️  ATENCIÓN: FIREBASE NO ESTÁ CONFIGURADO ⚠️');
    debugPrint('Detalle técnico: $e');
    debugPrint('Falta vincular el proyecto con \'flutterfire configure\'');
    debugPrint('-------------------------------------------------');
  }

  // Intentar restaurar sesión guardada (funcionalidad "Recordarme")
  final haySession = await AuthService.cargarSesionGuardada();

  runApp(MyApp(sesionGuardada: haySession));
}

class MyApp extends StatelessWidget {
  final bool sesionGuardada;

  const MyApp({super.key, required this.sesionGuardada});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Cicla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Si hay sesión guardada, ir directo al Home; si no, mostrar Login
      home: sesionGuardada && AuthService.usuarioActual != null
          ? HomeScreen(usuario: AuthService.usuarioActual!)
          : const LoginScreen(),
    );
  }
}
