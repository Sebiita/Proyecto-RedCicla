from data.database import rutas_ref, fichas_ref, camiones_ref, puntos_ref
from datetime import datetime
from collections import defaultdict
import math


def _ruta_en_periodo(
    ruta_data: dict, fecha_inicio: str = None, fecha_fin: str = None
) -> bool:
    """Verifica si una ruta está dentro del período indicado."""
    fecha_ruta = ruta_data.get("fecha")
    if not fecha_ruta:
        return False

    # Normalizar a string YYYY-MM-DD
    fecha_ruta_str = str(fecha_ruta)

    if fecha_inicio and fecha_ruta_str < fecha_inicio:
        return False
    if fecha_fin and fecha_ruta_str > fecha_fin:
        return False
    return True


def _parse_timestamp(timestamp: str) -> datetime:
    """Convierte un timestamp ISO 8601 a datetime."""
    if not timestamp:
        return None
    try:
        return datetime.fromisoformat(timestamp)
    except Exception:
        return None


def _distancia_haversine(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """
    Calcula la distancia en kilómetros entre dos coordenadas GPS
    usando la fórmula de Haversine.
    """
    R = 6371.0  # Radio de la Tierra en kilómetros

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)

    cos_lat1 = math.cos(lat1_rad)
    cos_lat2 = math.cos(lat2_rad)
    sin_dlon = math.sin(delta_lon / 2)
    sin_dlat = math.sin(delta_lat / 2)
    a = sin_dlat ** 2 + cos_lat1 * cos_lat2 * sin_dlon ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def _calcular_distancia_ruta(puntos_ids: list, puntos_data: dict) -> float:
    """
    Calcula la distancia total de una ruta sumando las distancias
    entre puntos consecutivos usando sus coordenadas.
    """
    distancia_total = 0.0
    coordenadas = []

    for punto_id in puntos_ids:
        punto = puntos_data.get(punto_id)
        if punto:
            lat = punto.get("latitud")
            lon = punto.get("longitud")
            if lat is not None and lon is not None:
                coordenadas.append((float(lat), float(lon)))

    for i in range(1, len(coordenadas)):
        distancia_total += _distancia_haversine(
            coordenadas[i - 1][0], coordenadas[i - 1][1],
            coordenadas[i][0], coordenadas[i][1]
        )

    return distancia_total


def services_generar_reporte_rendimiento(
    fecha_inicio: str = None,
    fecha_fin: str = None,
    camion_asignado: str = None,
    chofer_asignado: str = None
):
    """
    Genera un reporte de rendimiento agregando datos de rutas, fichas,
    camiones y puntos.

    Métricas incluidas:
    - Total de rutas en el período (con filtros opcionales).
    - Rutas completadas vs pendientes vs en curso.
    - Peso total recolectado desde fichas_realizadas.
    - Peso promedio por ruta.
    - Tiempo total y promedio por ruta (en horas), calculado desde timestamps.
    - Distancia total y promedio por ruta (en km), desde coordenadas GPS.
    - Rendimiento por camión (kilos recolectados / capacidad).
    - Eficiencia por conductor (kilos y rutas).
    """
    try:
        # --- 1. Obtener rutas ---
        rutas = []
        docs = rutas_ref.stream()
        for doc in docs:
            ruta_data = doc.to_dict()
            ruta_data["id"] = doc.id
            rutas.append(ruta_data)

        # --- 2. Aplicar filtros en memoria ---
        rutas_filtradas = []
        for ruta in rutas:
            if not _ruta_en_periodo(ruta, fecha_inicio, fecha_fin):
                continue
            if camion_asignado and \
                    ruta.get("camion_asignado") != camion_asignado:
                continue
            if chofer_asignado and \
                    ruta.get("chofer_asignado") != chofer_asignado:
                continue
            rutas_filtradas.append(ruta)

        total_rutas = len(rutas_filtradas)

        # --- 3. Contar rutas por estado ---
        rutas_por_estado = defaultdict(int)
        for ruta in rutas_filtradas:
            estado = ruta.get("estado", "Desconocido")
            rutas_por_estado[estado] += 1

        # Asegurar estados clave siempre presentes
        for estado in ["Pendiente", "En curso", "Finalizada"]:
            if estado not in rutas_por_estado:
                rutas_por_estado[estado] = 0

        # --- 4. Obtener todas las fichas ---
        fichas = []
        fichas_docs = fichas_ref.stream()
        for doc in fichas_docs:
            ficha_data = doc.to_dict()
            ficha_data["id"] = doc.id
            fichas.append(ficha_data)

        # IDs de rutas filtradas
        ids_rutas_filtradas = {r["id"] for r in rutas_filtradas}

        # Filtrar fichas que pertenezcan a las rutas del reporte
        fichas_filtradas = [
            f for f in fichas
            if f.get("ruta_id") in ids_rutas_filtradas
        ]

        # Agrupar fichas por ruta para cálculo de tiempo
        fichas_por_ruta = defaultdict(list)
        for ficha in fichas_filtradas:
            fichas_por_ruta[ficha.get("ruta_id")].append(ficha)

        # Calcular peso total recogido
        peso_total_recogido = sum(
            float(f.get("kilos_recogidos", 0) or 0)
            for f in fichas_filtradas
        )

        peso_promedio_por_ruta = (
            peso_total_recogido / total_rutas if total_rutas > 0 else 0.0
        )

        # --- 5. Calcular tiempo total y distancia total ---
        tiempo_total_horas = 0.0
        distancia_total_km = 0.0

        # Obtener todos los puntos para calcular distancias
        puntos_data = {}
        puntos_docs = puntos_ref.stream()
        for doc in puntos_docs:
            puntos_data[doc.id] = doc.to_dict()

        for ruta in rutas_filtradas:
            # Tiempo: diferencia entre primera y última ficha de la ruta
            fichas_ruta = fichas_por_ruta.get(ruta["id"], [])
            if fichas_ruta:
                timestamps = [
                    _parse_timestamp(f.get("timestamp"))
                    for f in fichas_ruta
                    if f.get("timestamp")
                ]
                timestamps = [t for t in timestamps if t is not None]
                if len(timestamps) >= 2:
                    primera = min(timestamps)
                    ultima = max(timestamps)
                    duracion_horas = (ultima - primera).total_seconds() / 3600
                    tiempo_total_horas += duracion_horas

            # Distancia: suma de distancias entre puntos consecutivos
            puntos_ids = ruta.get("puntos", [])
            if puntos_ids:
                distancia_total_km += _calcular_distancia_ruta(
                    puntos_ids, puntos_data
                )

        tiempo_promedio_por_ruta_horas = (
            tiempo_total_horas / total_rutas if total_rutas > 0 else 0.0
        )
        distancia_promedio_por_ruta_km = (
            distancia_total_km / total_rutas if total_rutas > 0 else 0.0
        )

        # Eficiencia: kg por km recorrido
        eficiencia_kg_por_km = (
            peso_total_recogido / distancia_total_km
            if distancia_total_km > 0 else 0.0
        )

        # --- 6. Rendimiento por camión ---
        kilos_por_camion = defaultdict(float)
        rutas_por_camion = defaultdict(int)

        for ruta in rutas_filtradas:
            camion = ruta.get("camion_asignado")
            if camion:
                rutas_por_camion[camion] += 1

        for ficha in fichas_filtradas:
            ruta_id = ficha.get("ruta_id")
            for ruta in rutas_filtradas:
                if ruta["id"] == ruta_id:
                    camion = ruta.get("camion_asignado")
                    if camion:
                        kilos_por_camion[camion] += float(
                            ficha.get("kilos_recogidos", 0) or 0
                        )
                    break

        # Obtener capacidades de camiones
        camiones_data = {}
        camiones_docs = camiones_ref.stream()
        for doc in camiones_docs:
            camion_dict = doc.to_dict()
            camion_dict["patente"] = doc.id
            camiones_data[doc.id] = camion_dict

        rendimiento_por_camion = []
        for patente in rutas_por_camion.keys():
            camion = camiones_data.get(patente, {})
            capacidad = float(camion.get("capacidad", 0) or 0)
            kilos = kilos_por_camion.get(patente, 0.0)
            rendimiento = (kilos / capacidad) if capacidad > 0 else 0.0
            rendimiento_por_camion.append({
                "patente": patente,
                "capacidad": capacidad,
                "kilos_recogidos": round(kilos, 2),
                "rendimiento": round(rendimiento, 4),
                "rutas_asignadas": rutas_por_camion.get(patente, 0)
            })

        # --- 7. Eficiencia por conductor ---
        kilos_por_conductor = defaultdict(float)
        rutas_por_conductor = defaultdict(int)

        for ruta in rutas_filtradas:
            chofer = ruta.get("chofer_asignado")
            if chofer:
                rutas_por_conductor[chofer] += 1

        for ficha in fichas_filtradas:
            ruta_id = ficha.get("ruta_id")
            for ruta in rutas_filtradas:
                if ruta["id"] == ruta_id:
                    chofer = ruta.get("chofer_asignado")
                    if chofer:
                        kilos_por_conductor[chofer] += float(
                            ficha.get("kilos_recogidos", 0) or 0
                        )
                    break

        eficiencia_por_conductor = []
        for chofer in rutas_por_conductor.keys():
            rutas_count = rutas_por_conductor.get(chofer, 0)
            kilos = kilos_por_conductor.get(chofer, 0.0)
            promedio = (kilos / rutas_count) if rutas_count > 0 else 0.0
            eficiencia_por_conductor.append({
                "chofer_email": chofer,
                "rutas_realizadas": rutas_count,
                "kilos_recogidos": round(kilos, 2),
                "peso_promedio_por_ruta": round(promedio, 2)
            })

        return {
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin,
            "total_rutas": total_rutas,
            "rutas_por_estado": dict(rutas_por_estado),
            "peso_total_recogido_kg": round(peso_total_recogido, 2),
            "peso_promedio_por_ruta_kg": round(peso_promedio_por_ruta, 2),
            "tiempo_total_horas": round(tiempo_total_horas, 2),
            "tiempo_promedio_por_ruta_horas": round(
                tiempo_promedio_por_ruta_horas, 2
            ),
            "distancia_total_km": round(distancia_total_km, 2),
            "distancia_promedio_por_ruta_km": round(
                distancia_promedio_por_ruta_km, 2
            ),
            "eficiencia_kg_por_km": round(eficiencia_kg_por_km, 2),
            "rendimiento_por_camion": rendimiento_por_camion,
            "eficiencia_por_conductor": eficiencia_por_conductor
        }

    except Exception as e:
        return {"error": f"Error al generar reporte: {str(e)}"}
