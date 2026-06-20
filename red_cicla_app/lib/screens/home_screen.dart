import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ficha_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista dinámica que reemplaza a los datos duros
  List<String> puntos = [];
  bool cargando = true;
  String? errorMensaje;

  @override
  void initState() {
    super.initState();
    obtenerPuntosDelBackend();
  }

 // Función asíncrona para conectarse a FastAPI corregida
  Future<void> obtenerPuntosDelBackend() async {
    final url = Uri.parse('http://10.0.2.2:8000/puntos/api/puntos');

    try {
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        // 1. Decodificamos el JSON como un Mapa, no como una Lista
        final Map<String, dynamic> cuerpoJson = json.decode(respuesta.body);
        
        // 2. Extraemos la lista interna que viene bajo la clave "puntos"
        final List<dynamic> listaPuntos = cuerpoJson['puntos'] ?? [];
        
        setState(() {
          // 3. Mapeamos cada objeto de la lista para extraer su 'municipalidad'
          puntos = listaPuntos.map((punto) {
            if (punto is Map) {
              return punto['municipalidad']?.toString() ?? 'Punto de Reciclaje';
            }
            return punto.toString();
          }).toList();
          
          errorMensaje = null; // Limpiamos cualquier error previo
          cargando = false;
        });
      } else {
        setState(() {
          errorMensaje = 'Error del servidor: ${respuesta.statusCode}';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMensaje = 'No se pudo procesar la información del backend.';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final altoPantalla = MediaQuery.of(context).size.height;
    final int puntosDiarios = puntos.length;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => print("Abriendo el mapa..."),
        backgroundColor: Colors.blue[600],
        shape: const CircleBorder(),
        child: const Icon(Icons.map, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Ruta'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
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
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: obtenerPuntosDelBackend, // Botón para refrescar datos
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.green[200]!, width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          cargando ? '...' : 'ONLINE',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camión: AB-CD-12 | Ayudante: Pedro S.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),

            // 2. TEXTO DE PUNTOS DE HOY
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
              child: Text(
                'PUNTOS DE HOY ($puntosDiarios)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // 3. CUERPO DINÁMICO (Carga, Error o Lista)
            Expanded(
              child: _construirContenidoPrincipal(puntosDiarios),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para alternar vistas según el estado de la red
  Widget _construirContenidoPrincipal(int puntosDiarios) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (errorMensaje != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(errorMensaje!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => cargando = true);
                  obtenerPuntosDelBackend();
                },
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      );
    }

    if (puntos.isEmpty) {
      return const Center(child: Text('No hay puntos registrados para hoy.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: puntosDiarios,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FichaScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[400]!, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puntos[index],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A 200 metros de tu posición',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}