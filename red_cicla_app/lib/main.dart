import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importaremos la pantalla que vamos a crear

void main() {
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
