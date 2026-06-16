import 'package:flutter/material.dart';
import 'ficha_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final altoPantalla = MediaQuery.of(context).size.height;

    // 1. SIMULAMOS LOS DATOS QUE LLEGARÍAN DEL BACKEND
    // Cada punto ahora tiene un ID para poder referenciarlo en las fichas
    final String rutaId = 'ruta_15_06_2026'; // ID de la ruta del día
    final List<Map<String, dynamic>> puntos = [
      {'id': 'punto_01', 'nombre': 'Plaza de Armas', 'estado': 'pendiente'},
      {'id': 'punto_02', 'nombre': 'Supermercado Líder', 'estado': 'pendiente'},
      {'id': 'punto_03', 'nombre': 'Calle El Roble 450', 'estado': 'pendiente'},
      {'id': 'punto_04', 'nombre': 'Parque Central', 'estado': 'pendiente'},
      {'id': 'punto_05', 'nombre': 'Hospital San Juan', 'estado': 'pendiente'},
    ];
    // La cantidad de puntos se calcula sola viendo el tamaño de la lista
    final int puntosDiarios = puntos.length;

    return Scaffold(
      backgroundColor: Colors.white,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Abriendo el mapa...");
        },
        backgroundColor: Colors.blue[600],
        shape: const CircleBorder(), // Lo hace completamente redondo
        child: const Icon(
          Icons.map,
          color: Colors.white,
        ), // Ícono de mapa de Flutter
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green, // Color si está seleccionado
        unselectedItemColor: Colors.grey, // Color si no lo está
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.route), // Ícono de ruta
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), // Ícono de estadísticas
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ícono de perfil
            label: 'Perfil',
          ),
        ],
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ENCABEZADO VERDE
            Container(
              height: altoPantalla * 0.15,
              width: double.infinity,
              color: Colors.green,
              padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ruta: Zona Norte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.green[200]!,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camión: AB-CD-12 | Ayudante: Pedro S.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 2. TEXTO DE PUNTOS DE HOY
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: 10,
              ),
              child: Text(
                'PUNTOS DE HOY ($puntosDiarios)', // Inyectamos la variable
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5, // Le da un toque espaciado más elegante
                ),
              ),
            ),

            // 3. LA LISTA DINÁMICA DE FICHAS (ListView)
            Expanded(
              // ListView.builder crea elementos "infinitos" basándose en tu lista
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: puntosDiarios, // Le decimos que dibuje 5 cosas
                itemBuilder: (context, index) {
                  final punto = puntos[index];
                  // ==========================================
                  // GESTURE DETECTOR: Envuelve la ficha para hacerla clickeable
                  // ==========================================
                  return GestureDetector(
                    onTap: () {
                      // El hipervínculo hacia la pantalla de la ficha
                      // Ahora pasamos los IDs necesarios para crear la ficha
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FichaScreen(
                            rutaId: rutaId,
                            puntoId: punto['id'],
                            nombrePunto: punto['nombre'],
                          ),
                        ),
                      );
                    },

                    // Tu diseño original del Container va aquí adentro como "child"
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: 16,
                      ), // Espacio entre cada ficha
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green[400]!,
                          width: 2,
                        ), // Borde verde
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // EL ÍCONO
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              shape: BoxShape
                                  .circle, // Hace que el fondo del ícono sea redondo
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // EL TEXTO DEL PUNTO
                          Expanded(
                            // Usamos Expanded para que el texto no empuje los bordes si es muy largo
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  punto['nombre'], // INYECTAMOS EL NOMBRE DESDE EL DICCIONARIO
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'A 200 metros de tu posición',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  // ==========================================
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
