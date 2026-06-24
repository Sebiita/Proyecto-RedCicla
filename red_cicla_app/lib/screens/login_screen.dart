import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Controllers ───────────────────────────────────────────────
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  // ── Estado ───────────────────────────────────────────────────
  bool _cargando = false;
  bool _recordarme = false;
  bool _mostrarContrasena = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ── Lógica de login ──────────────────────────────────────────
  Future<void> _iniciarSesion() async {
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    // Validación básica de campos vacíos
    if (correo.isEmpty || contrasena.isEmpty) {
      _mostrarSnackBar('Por favor, completa todos los campos.', Colors.orange);
      return;
    }

    setState(() => _cargando = true);

    final resultado = await AuthService.login(
      correo: correo,
      contrasena: contrasena,
      recordarme: _recordarme,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      // Login exitoso → navegar a HomeScreen reemplazando la pila
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            usuario: resultado['usuario'] as Map<String, dynamic>,
          ),
        ),
      );
    } else {
      // Mostrar el error que devolvió el backend
      final mensajeError = resultado['error'] as String? ?? 'Error desconocido';
      _mostrarSnackBar(mensajeError, Colors.red[700]!);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. CABECERA VERDE CON LOGO
            Container(
              height: altoPantalla * 0.30,
              width: double.infinity,
              color: Colors.green,
              child: const Center(
                child: Text(
                  'LOGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 2. FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.grey[100],
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        '¡Bienvenido!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para comenzar tu ruta de reciclaje.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Campo Correo ─────────────────────────
                      Text(
                        'CORREO ELECTRÓNICO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_cargando,
                        decoration: InputDecoration(
                          hintText: 'ejemplo@ecociclo.cl',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                                color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Campo Contraseña ──────────────────────
                      Text(
                        'CONTRASEÑA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contrasenaController,
                        obscureText: !_mostrarContrasena,
                        enabled: !_cargando,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.lock_outlined,
                              color: Colors.grey),
                          // Botón para mostrar/ocultar contraseña
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarContrasena
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => _mostrarContrasena = !_mostrarContrasena),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                                color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Recordarme + ¿Olvidaste? ──────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _recordarme,
                                onChanged: _cargando
                                    ? null
                                    : (valor) => setState(
                                        () => _recordarme = valor ?? false),
                                activeColor: Colors.green,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Text(
                                'Recordarme',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 15),
                              ),
                            ],
                          ),
                          Text(
                            '¿Olvidaste la clave?',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // ── Botón Entrar ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey[400],
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ENTRAR AL SISTEMA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Pie: ¿No tienes cuenta? ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _mostrarSnackBar(
                                  'Contacta al administrador del sistema.',
                                  Colors.green);
                            },
                            child: const Text(
                              'Pide acceso aquí',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
