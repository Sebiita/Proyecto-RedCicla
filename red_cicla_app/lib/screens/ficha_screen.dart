import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/ficha_service.dart';

class FichaScreen extends StatefulWidget {
  /// ID de la ruta actual (llave foránea)
  final String rutaId;

  /// ID del punto actual (llave foránea)
  final String puntoId;

  /// Nombre del punto (para mostrar en pantalla)
  final String nombrePunto;

  const FichaScreen({
    super.key,
    required this.rutaId,
    required this.puntoId,
    required this.nombrePunto,
  });

  @override
  State<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends State<FichaScreen> {
  // Controllers para capturar los datos del formulario
  final TextEditingController _kilosController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  // Estado del formulario
  bool _enviando = false;
  bool _guardadoLocal = false;

  @override
  void dispose() {
    _kilosController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // Variables de fotos
  File? _fotoAntes;
  File? _fotoDespues;
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarImagen(bool esAntes) async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto (Cámara)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (origen == null) return;

    try {
      final XFile? imagenSeleccionada = await _picker.pickImage(
        source: origen,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (imagenSeleccionada != null) {
        setState(() {
          if (esAntes) {
            _fotoAntes = File(imagenSeleccionada.path);
          } else {
            _fotoDespues = File(imagenSeleccionada.path);
          }
        });
      }
    } catch (e) {
      _mostrarSnackBar('❌ Error al seleccionar imagen: $e', Colors.red);
    }
  }

  Future<String> _subirImagen(File file, String subDir) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('fichas')
          .child(widget.rutaId)
          .child(subDir)
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error al subir imagen a Firebase Storage: $e');
      rethrow;
    }
  }

  /// Guarda la ficha localmente como diccionario y la envía al servidor
  Future<void> _finalizarRetiro() async {
    // Validar que los kilos estén llenos
    final kilosTexto = _kilosController.text.trim();
    if (kilosTexto.isEmpty) {
      _mostrarSnackBar('⚠️ Debes ingresar los kilos recogidos', Colors.orange);
      return;
    }

    final kilos = double.tryParse(kilosTexto);
    if (kilos == null || kilos <= 0) {
      _mostrarSnackBar('⚠️ Ingresa un valor numérico válido mayor a 0', Colors.orange);
      return;
    }

    // Validar fotos requeridas
    if (_fotoAntes == null) {
      _mostrarSnackBar('⚠️ Debes seleccionar la foto del ANTES', Colors.orange);
      return;
    }
    if (_fotoDespues == null) {
      _mostrarSnackBar('⚠️ Debes seleccionar la foto del DESPUÉS', Colors.orange);
      return;
    }

    setState(() => _enviando = true);

    String fotoAntesUrl = '';
    String fotoDespuesUrl = '';

    try {
      // Subir las imágenes
      fotoAntesUrl = await _subirImagen(_fotoAntes!, 'antes');
      fotoDespuesUrl = await _subirImagen(_fotoDespues!, 'despues');
    } catch (e) {
      setState(() => _enviando = false);
      _mostrarSnackBar('❌ Error al subir fotos: Revisa tu conexión a internet.', Colors.red);
      return;
    }

    // 1. CREAR EL DICCIONARIO Y GUARDARLO EN FIREBASE (Cache/Nube)
    await FichaService.crearFichaLocal(
      rutaId: widget.rutaId,
      puntoId: widget.puntoId,
      kilosRecogidos: kilos,
      observaciones: _observacionesController.text.trim(),
      fotoAntesUrl: fotoAntesUrl,
      fotoDespuesUrl: fotoDespuesUrl,
    );

    setState(() {
      _enviando = false;
      _guardadoLocal = true;
    });

    _mostrarSnackBar('✅ Ficha guardada exitosamente', Colors.green);
    
    // Volver a la pantalla anterior después de un momento
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo de la app
      // 1. EL ENCABEZADO (CON FLECHA DE ATRÁS AUTOMÁTICA)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Le da una sombrita muy sutil abajo
        iconTheme: const IconThemeData(color: Colors.grey), // Flecha gris
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ficha de Recolección',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.nombrePunto,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),

      // 2. EL CUERPO (Con Scroll por si el celular es pequeño)
      body: SingleChildScrollView(
        // Esto evita que el teclado tape los botones
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN 1: CANTIDAD DE VIDRIO ---
            const Text(
              'Cantidad de Vidrio (Kg)*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kilosController,
              // TRUCO 1: Abre el teclado con números y decimales
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: 15.5',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN 2: LAS FOTOS (ROW CON 2 CUADRADOS) ---
            Row(
              children: [
                // FOTO ANTES (Ocupa la mitad del espacio)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FOTO ANTES*',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _seleccionarImagen(true),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: _fotoAntes != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.file(
                                        _fotoAntes!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _fotoAntes = null);
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey,
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Subir Foto',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16), // Espacio entre las dos fotos
                // FOTO DESPUÉS (Ocupa la otra mitad)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FOTO DESPUÉS*',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _seleccionarImagen(false),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: _fotoDespues != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.file(
                                        _fotoDespues!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _fotoDespues = null);
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey,
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Subir Foto',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN 3: OBSERVACIONES (<textarea>) ---
            const Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesController,
              maxLines: 3, // TRUCO 2: Esto lo convierte en un textarea grande
              decoration: InputDecoration(
                hintText: 'Ej: Contenedor dañado, difícil acceso...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- SECCIÓN 4: BOTÓN FINALIZAR ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _finalizarRetiro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'FINALIZAR RETIRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Texto pequeño de sincronización con estado dinámico
            Center(
              child: Text(
                _guardadoLocal
                    ? '✅ Ficha procesada por Firebase'
                    : 'Firebase sincronizará automáticamente offline/online.',
                style: TextStyle(
                  fontSize: 10,
                  color: _guardadoLocal ? Colors.green : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
