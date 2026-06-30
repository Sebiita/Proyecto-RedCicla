import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> puntosDeReciclaje;
  final String? polylineCodificada;

  const MapaScreen({
    super.key,
    required this.puntosDeReciclaje,
    this.polylineCodificada,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Set<Marker> _marcadores = {};
  final Set<Polyline> _polylines = {};
  late CameraPosition _posicionInicial;
  bool _tieneCoordenadasValidas = false;

  @override
  void initState() {
    super.initState();
    _procesarPuntosYMarcadores();
    if (widget.polylineCodificada != null && widget.polylineCodificada!.isNotEmpty) {
      _decodificarPolyline();
    }
  }

  void _procesarPuntosYMarcadores() {
    double latInicial = -33.4489; // Ubicación por defecto si no hay datos (Santiago, Chile)
    double lngInicial = -70.6693;

    if (widget.puntosDeReciclaje.isNotEmpty) {
      for (var punto in widget.puntosDeReciclaje) {
        final double? lat = double.tryParse(punto['latitud']?.toString() ?? '');
        final double? lng = double.tryParse(punto['longitud']?.toString() ?? '');
        final String id = punto['id']?.toString() ?? UniqueKey().toString();
        final String titulo = punto['municipalidad']?.toString() ?? 'Punto de Reciclaje';
        final String subTitulo = 'Estado: ${punto['estado']} | Urgencia: ${punto['urgencia']}';

        if (lat != null && lng != null) {
          if (!_tieneCoordenadasValidas) {
            latInicial = lat;
            lngInicial = lng;
            _tieneCoordenadasValidas = true;
          }

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
      zoom: 14.0,
    );
  }

  void _decodificarPolyline() {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(widget.polylineCodificada!);
    
    if (result.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      for (var point in result) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('ruta_actual'),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 5,
          ),
        );
      });
    }
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
        polylines: _polylines,
        mapType: MapType.normal,
        myLocationButtonEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}