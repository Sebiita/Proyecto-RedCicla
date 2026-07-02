from data.database import db, puntos_ref, rutas_ref
import requests
import os
from pathlib import Path


def _obtener_google_maps_key():
    """Obtiene la API key de Google Maps desde .env"""
    env_path = Path(__file__).resolve().parent.parent.parent / '.env'
    if env_path.exists():
        for line in env_path.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if line.startswith('GOOGLE_MAPS_API_KEY='):
                return line.split('=', 1)[1].strip()
    return os.getenv('GOOGLE_MAPS_API_KEY', '')


def _obtener_coordenadas_puntos(puntos_ids: list):
    """Obtiene las coordenadas (lat, lng) de una lista de IDs de puntos."""
    coordenadas = {}
    for pid in puntos_ids:
        try:
            doc = puntos_ref.document(str(pid)).get()
            if doc.exists:
                data = doc.to_dict()
                lat = data.get('latitud')
                lng = data.get('longitud')
                if lat is not None and lng is not None:
                    coordenadas[str(pid)] = {'lat': float(lat), 'lng': float(lng)}
        except Exception as e:
            print(f"Error obteniendo punto {pid}: {e}")
    return coordenadas


def _generar_ruta_google_maps(puntos_ids: list):
    """
    Usa Google Maps Directions API para generar:
    - polyline: string codificada con la ruta
    - puntos_ordenados: lista de IDs de puntos en el orden optimizado
    
    El primer punto se usa como origen y destino (ruta circular).
    Los demás puntos son waypoints intermedios con optimización.
    """
    api_key = _obtener_google_maps_key()
    if not api_key or not api_key.startswith('AIza'):
        print("⚠️ No hay API key de Google Maps válida, no se puede generar polyline.")
        return None, None

    if len(puntos_ids) < 2:
        print("⚠️ Se necesitan al menos 2 puntos para generar una ruta.")
        return None, None

    coordenadas = _obtener_coordenadas_puntos(puntos_ids)
    
    if len(coordenadas) < 2:
        print("⚠️ No se encontraron suficientes coordenadas para los puntos.")
        return None, None

    # El primer punto es origen y destino (ruta circular)
    origen_id = puntos_ids[0]
    waypoint_ids = puntos_ids[1:]
    
    if origen_id not in coordenadas:
        print(f"⚠️ No se encontraron coordenadas para el punto de origen {origen_id}")
        return None, None

    origen_coords = coordenadas[origen_id]
    origin_str = f"{origen_coords['lat']},{origen_coords['lng']}"
    
    # Construir waypoints
    waypoints_strs = []
    waypoint_ids_validos = []
    for wid in waypoint_ids:
        wid_str = str(wid)
        if wid_str in coordenadas:
            c = coordenadas[wid_str]
            waypoints_strs.append(f"{c['lat']},{c['lng']}")
            waypoint_ids_validos.append(wid_str)

    if not waypoints_strs:
        print("⚠️ No hay waypoints válidos para generar la ruta.")
        return None, None

    # Llamar a Google Maps Directions API
    params = {
        'origin': origin_str,
        'destination': origin_str,  # Ruta circular: vuelve al origen
        'waypoints': 'optimize:true|' + '|'.join(waypoints_strs),
        'travelMode': 'driving',
        'key': api_key
    }

    try:
        resp = requests.get(
            'https://maps.googleapis.com/maps/api/directions/json',
            params=params,
            timeout=15
        )
        data = resp.json()

        if data.get('status') != 'OK':
            print(f"❌ Google Maps Directions API error: {data.get('status')} - {data.get('error_message', '')}")
            return None, None

        route = data['routes'][0]
        polyline = route['overview_polyline']['points']
        
        # Orden optimizado de waypoints
        waypoint_order = route.get('waypoint_order', list(range(len(waypoint_ids_validos))))
        
        # Construir lista de puntos ordenados: origen + waypoints optimizados + origen (retorno)
        puntos_ordenados = [str(origen_id)]
        for idx in waypoint_order:
            puntos_ordenados.append(waypoint_ids_validos[idx])
        puntos_ordenados.append(str(origen_id))

        print(f"✅ Ruta generada: {len(puntos_ordenados)} puntos, polyline de {len(polyline)} chars")
        return polyline, puntos_ordenados

    except Exception as e:
        print(f"❌ Error al llamar Google Maps Directions API: {e}")
        return None, None


def services_crear_ruta(fecha: str, camion_asignado: str, chofer_asignado: str, 
                       ayudante_asignado: str, puntos: list, estado: str = "Pendiente",
                       polyline: str = None, puntos_ordenados: list = None):
    """Crea una nueva ruta"""
    try:
        # Si no se proporcionó polyline/puntos_ordenados, generarlos automáticamente
        if (polyline is None or puntos_ordenados is None) and puntos and len(puntos) >= 2:
            print("🔄 Generando ruta con Google Maps Directions API...")
            gen_polyline, gen_puntos_ord = _generar_ruta_google_maps(puntos)
            if polyline is None and gen_polyline:
                polyline = gen_polyline
            if puntos_ordenados is None and gen_puntos_ord:
                puntos_ordenados = gen_puntos_ord

        nueva_ruta = {
            "fecha": fecha,
            "camion_asignado": camion_asignado,
            "chofer_asignado": chofer_asignado,
            "ayudante_asignado": ayudante_asignado,
            "puntos": puntos,
            "estado": estado
        }
        if polyline is not None:
            nueva_ruta["polyline"] = polyline
        if puntos_ordenados is not None:
            nueva_ruta["puntos_ordenados"] = puntos_ordenados
        
        # Firestore genera automáticamente el ID
        doc_ref = rutas_ref.document()
        doc_ref.set(nueva_ruta)
        
        return {
            "mensaje": "Ruta creada correctamente",
            "ruta": {
                **nueva_ruta,
                "id": doc_ref.id
            }
        }
    except Exception as e:
        return {"error": f"Error al crear ruta: {str(e)}"}


def services_leer_ruta(ruta_id: str):
    """Lee una ruta por ID"""
    try:
        ruta = rutas_ref.document(ruta_id).get()
        
        if not ruta.exists:
            return {"error": "Ruta no encontrada"}
        
        ruta_data = ruta.to_dict()
        ruta_data["id"] = ruta.id
        return {"ruta": ruta_data}
    except Exception as e:
        return {"error": f"Error al leer ruta: {str(e)}"}


def services_leer_todas_rutas():
    """Lee todas las rutas"""
    try:
        rutas = []
        docs = rutas_ref.stream()
        
        for doc in docs:
            ruta_data = doc.to_dict()
            ruta_data["id"] = doc.id
            rutas.append(ruta_data)
        
        return {"rutas": rutas}
    except Exception as e:
        return {"error": f"Error al leer rutas: {str(e)}"}


def services_actualizar_ruta(ruta_id: str, fecha: str = None, camion_asignado: str = None,
                            chofer_asignado: str = None, ayudante_asignado: str = None,
                            puntos: list = None, estado: str = None,
                            polyline: str = None, puntos_ordenados: list = None):
    """Actualiza datos de una ruta"""
    try:
        ruta_ref = rutas_ref.document(ruta_id)
        
        if not ruta_ref.get().exists:
            return {"error": "Ruta no encontrada"}

        # Si se actualizan los puntos pero no la polyline, regenerar automáticamente
        if puntos is not None and (polyline is None or puntos_ordenados is None) and len(puntos) >= 2:
            print("🔄 Regenerando ruta con Google Maps Directions API...")
            gen_polyline, gen_puntos_ord = _generar_ruta_google_maps(puntos)
            if polyline is None and gen_polyline:
                polyline = gen_polyline
            if puntos_ordenados is None and gen_puntos_ord:
                puntos_ordenados = gen_puntos_ord
        
        actualizaciones = {}
        if fecha:
            actualizaciones["fecha"] = fecha
        if camion_asignado:
            actualizaciones["camion_asignado"] = camion_asignado
        if chofer_asignado:
            actualizaciones["chofer_asignado"] = chofer_asignado
        if ayudante_asignado:
            actualizaciones["ayudante_asignado"] = ayudante_asignado
        if puntos is not None:
            actualizaciones["puntos"] = puntos
        if estado:
            actualizaciones["estado"] = estado
        if polyline is not None:
            actualizaciones["polyline"] = polyline
        if puntos_ordenados is not None:
            actualizaciones["puntos_ordenados"] = puntos_ordenados
        
        if actualizaciones:
            ruta_ref.update(actualizaciones)
        
        return {"mensaje": "Ruta actualizada correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar ruta: {str(e)}"}


def services_eliminar_ruta(ruta_id: str):
    """Elimina una ruta por ID"""
    try:
        ruta_ref = rutas_ref.document(ruta_id)
        
        if not ruta_ref.get().exists:
            return {"error": "Ruta no encontrada"}
        
        ruta_ref.delete()
        
        return {"mensaje": "Ruta eliminada correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar ruta: {str(e)}"}