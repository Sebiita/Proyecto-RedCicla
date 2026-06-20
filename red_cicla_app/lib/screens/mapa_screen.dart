import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> puntosDeReciclaje;

  const MapaScreen({super.key, required this.puntosDeReciclaje});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Set<Marker> _marcadores = {};
  late CameraPosition _posicionInicial;
  bool _tieneCoordenadasValidas = false;

  @override
  void initState() {
    super.initState();
    _procesarPuntosYMarcadores();
  }

  void _procesarPuntosYMarcadores() {
    double latInicial = -33.4489; // Ubicación por defecto si no hay datos (Santiago, Chile)
    double lngInicial = -70.6693;

    if (widget.puntosDeReciclaje.isNotEmpty) {
      for (var punto in widget.puntosDeReciclaje) {
        // Obtenemos latitud y longitud asegurando que se procesen como double
        final double? lat = double.tryParse(punto['latitud']?.toString() ?? '');
        final double? lng = double.tryParse(punto['longitud']?.toString() ?? '');
        final String id = punto['id']?.toString() ?? UniqueKey().toString();
        final String titulo = punto['municipalidad']?.toString() ?? 'Punto de Reciclaje';
        final String subTitulo = 'Estado: ${punto['estado']} | Urgencia: ${punto['urgencia']}';

        if (lat != null && lng != null) {
          if (!_tieneCoordenadasValidas) {
            // Centramos la cámara en el primer punto válido que encontremos
            latInicial = lat;
            lngInicial = lng;
            _tieneCoordenadasValidas = true;
          }

          // Añadimos el pin al Set de marcadores de Google Maps
          _marcadores.add(
            Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: titulo,
                snippet: subTitulo,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
    }

    _posicionInicial = CameraPosition(
      target: LatLng(latInicial, lngInicial),
      zoom: 14.0, // Nivel de zoom de calle/barrio
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Puntos', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GoogleMap(
        initialCameraPosition: _posicionInicial,
        markers: _marcadores,
        mapType: MapType.normal,
        myLocationButtonEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}