import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart'; 
import 'services/ficha_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Envolvemos Firebase en un try-catch para evitar la pantalla negra
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    debugPrint("Firebase listo!");
  } catch (e) {
    debugPrint("-------------------------------------------------");
    debugPrint("?? ATENCI�N: FIREBASE NO EST� CONFIGURADO ??");
    debugPrint("Detalle t�cnico: $e");
    debugPrint("Falta vincular el proyecto con 'flutterfire configure'");
    debugPrint("-------------------------------------------------");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Cicla',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
