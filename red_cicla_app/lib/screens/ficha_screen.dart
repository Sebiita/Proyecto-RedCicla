import 'package:flutter/material.dart';

class FichaScreen extends StatelessWidget {
  const FichaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo de la app
      // 1. EL ENCABEZADO (CON FLECHA DE ATRÁS AUTOMÁTICA)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Le da una sombrita muy sutil abajo
        iconTheme: const IconThemeData(color: Colors.grey), // Flecha gris
        title: const Text(
          'Ficha de Recolección',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                      // El recuadro de la foto
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          // Nota: En Flutter nativo el borde punteado requiere un paquete extra (dotted_border).
                          // Aquí usamos un borde sólido claro para mantenerlo simple y sin instalar nada extra aún.
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: const Center(
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
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: const Center(
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
                onPressed: () {
                  print("¡Retiro guardado!");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
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

            // Texto pequeño de sincronización
            const Center(
              child: Text(
                'Se sincronizará automáticamente al detectar señal.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
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
