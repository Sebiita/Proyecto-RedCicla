import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importaremos la pantalla que vamos a crear
import 'services/ficha_service.dart'; // Servicio de fichas (persistencia local)
import 'services/sync_manager.dart'; // Sincronización automática

void main() async {
  // Necesario para usar SharedPreferences antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar fichas pendientes desde disco (por si la app se cerró con fichas sin enviar)
  await FichaService.inicializar();

  // 2. Iniciar el SyncManager (escucha cambios de red y sincroniza automáticamente)
  SyncManager.iniciar();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Cicla',
      debugShowCheckedModeBanner:
          false, // Esto quita la etiqueta roja de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Aquí le decimos que la primera pantalla sea tu Login
      home: const LoginScreen(),
    );
  }
}
