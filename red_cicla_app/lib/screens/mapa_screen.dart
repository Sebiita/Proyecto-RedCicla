import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> puntosDeReciclaje;
  final String? polylineCodificada;
  final List<String>? puntosOrdenados;

  const MapaScreen({
    super.key,
    required this.puntosDeReciclaje,
    this.polylineCodificada,
    this.puntosOrdenados,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Set<Marker> _marcadores = {};
  final Set<Polyline> _polylines = {};
  
  // Se cambia a nullable para evitar el LateInitializationError
  CameraPosition? _posicionInicial; 
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
    double latInicial = -33.4489; 
    double lngInicial = -70.6693;

    if (widget.puntosDeReciclaje.isEmpty) return;

    // Colecciones locales temporales para evitar múltiples setStates
    final Set<Marker> marcadoresLocales = {};

    if (widget.puntosOrdenados != null && widget.puntosOrdenados!.isNotEmpty) {
      int indexParada = 1;
      
      for (int i = 0; i < widget.puntosOrdenados!.length; i++) {
        final puntoId = widget.puntosOrdenados![i];
        
        final punto = widget.puntosDeReciclaje.firstWhere(
          (p) => p['id']?.toString() == puntoId,
          orElse: () => <String, dynamic>{},
        );

        if (punto.isEmpty) continue;

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

          bool esCanton = (i == 0 || i == widget.puntosOrdenados!.length - 1);
          String tituloFinal = titulo;
          BitmapDescriptor icono;

          if (esCanton) {
            tituloFinal = 'Cantón: $titulo';
            icono = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
          } else {
            tituloFinal = '$indexParada. $titulo';
            indexParada++;
            icono = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          }

          marcadoresLocales.add(
            Marker(
              markerId: MarkerId('${id}_$i'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: tituloFinal,
                snippet: subTitulo,
              ),
              icon: icono,
              zIndex: esCanton ? 10 : 1,
            ),
          );
        }
      }
    } else {
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

          marcadoresLocales.add(
            Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: titulo, snippet: subTitulo),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
    }

    // UN SOLO setState al final de procesar todo el set
    setState(() {
      _marcadores.addAll(marcadoresLocales);
      _posicionInicial = CameraPosition(
        target: LatLng(latInicial, lngInicial),
        zoom: 14.0,
      );
    });
  }

  void _decodificarPolyline() {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(widget.polylineCodificada!);
    
    if (result.isNotEmpty) {
      List<LatLng> polylineCoordinates = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

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
      // Mostramos un indicador de carga si la posición inicial aún no se procesa
      body: _posicionInicial == null 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : GoogleMap(
            initialCameraPosition: _posicionInicial!,
            markers: _marcadores,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            compassEnabled: true,
          ),
    );
  }
}