from fastapi import APIRouter
from data.database import rutas_ref, fichas_ref, puntos_ref
from datetime import datetime, timezone, timedelta

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

# Zona horaria de Chile (UTC-4)
CHILE_TZ = timezone(timedelta(hours=-4))


def _fecha_hoy_chile() -> str:
    """Retorna la fecha de hoy en Chile como string YYYY-MM-DD"""
    return datetime.now(CHILE_TZ).strftime("%Y-%m-%d")


@router.get("/hoy")
def dashboard_hoy():
    """
    Retorna un resumen del avance de recolección del día actual.

    Para cada ruta de hoy:
      - Información básica (camión, chofer, ayudante, estado)
      - Lista de puntos con su estado: 'completado' | 'en_espera'
        Un punto se considera completado si existe al menos una ficha
        en 'fichas_realizadas' con ese punto_id y ruta_id.

    Respuesta:
    {
        "fecha": "YYYY-MM-DD",
        "rutas": [
            {
                "id": "...",
                "camion_asignado": "...",
                "chofer_asignado": "...",
                "ayudante_asignado": "...",
                "estado": "...",
                "puntos_estado": [
                    {
                        "punto_id": "...",
                        "estado_recoleccion": "completado" | "en_espera",
                        "municipalidad": "...",
                        "urgencia": "...",
                        "capacidad_maxima": 0,
                        "capacidad_ocupada": 0,
                        "kilos_recogidos": 0,   # 0 si en_espera
                        "timestamp_ficha": null | "..."
                    }
                ],
                "total_puntos": 0,
                "puntos_completados": 0,
                "porcentaje_avance": 0.0
            }
        ],
        "resumen": {
            "total_rutas": 0,
            "total_puntos": 0,
            "total_completados": 0,
            "total_en_espera": 0,
            "porcentaje_global": 0.0
        }
    }
    """
    try:
        fecha_hoy = _fecha_hoy_chile()

        # ── 1. Obtener rutas del día ──────────────────────────────────────────
        rutas_hoy = []
        docs_rutas = rutas_ref.where("fecha", "==", fecha_hoy).stream()
        for doc in docs_rutas:
            data = doc.to_dict()
            data["id"] = doc.id
            rutas_hoy.append(data)

        if not rutas_hoy:
            return {
                "fecha": fecha_hoy,
                "rutas": [],
                "resumen": {
                    "total_rutas": 0,
                    "total_puntos": 0,
                    "total_completados": 0,
                    "total_en_espera": 0,
                    "porcentaje_global": 0.0
                }
            }

        # ── 2. Recolectar todos los IDs de puntos involucrados ───────────────
        todos_punto_ids = set()
        for ruta in rutas_hoy:
            for pid in ruta.get("puntos", []):
                todos_punto_ids.add(pid)

        # ── 3. Obtener datos de puntos de Firestore (en lote) ─────────────────
        puntos_info = {}
        for pid in todos_punto_ids:
            try:
                doc = puntos_ref.document(pid).get()
                if doc.exists:
                    puntos_info[pid] = doc.to_dict()
                else:
                    puntos_info[pid] = {}
            except Exception:
                puntos_info[pid] = {}

        # ── 4. Obtener fichas de las rutas de hoy ────────────────────────────
        # Índice: (ruta_id, punto_id) → ficha más reciente
        fichas_index = {}
        for ruta in rutas_hoy:
            ruta_id = ruta["id"]
            try:
                docs_fichas = fichas_ref.where("ruta_id", "==", ruta_id).stream()
                for doc in docs_fichas:
                    f = doc.to_dict()
                    key = (ruta_id, f.get("punto_id", ""))
                    # Si hay múltiples fichas para el mismo punto, quedarse con la más reciente
                    if key not in fichas_index:
                        fichas_index[key] = f
                    else:
                        # Comparar timestamps (ISO 8601, orden lexicográfico funciona)
                        if (f.get("timestamp") or "") > (fichas_index[key].get("timestamp") or ""):
                            fichas_index[key] = f
            except Exception:
                pass  # Si falla la consulta de fichas de una ruta, se ignora

        # ── 5. Construir respuesta ────────────────────────────────────────────
        resumen_total_puntos = 0
        resumen_total_completados = 0

        rutas_resultado = []
        for ruta in rutas_hoy:
            ruta_id = ruta["id"]
            puntos_ids = ruta.get("puntos", [])
            puntos_estado = []

            completados = 0
            for pid in puntos_ids:
                ficha = fichas_index.get((ruta_id, pid))
                info = puntos_info.get(pid, {})

                if ficha:
                    estado_rec = "completado"
                    completados += 1
                    kilos = ficha.get("kilos_recogidos", 0)
                    ts = ficha.get("timestamp")
                else:
                    estado_rec = "en_espera"
                    kilos = 0
                    ts = None

                puntos_estado.append({
                    "punto_id": pid,
                    "estado_recoleccion": estado_rec,
                    "municipalidad": info.get("municipalidad", "Sin nombre"),
                    "urgencia": info.get("urgencia", "Normal"),
                    "capacidad_maxima": info.get("capacidad_maxima", 0),
                    "capacidad_ocupada": info.get("capacidad_ocupada", 0),
                    "kilos_recogidos": kilos,
                    "timestamp_ficha": ts
                })

            total_pts = len(puntos_ids)
            porcentaje = round((completados / total_pts * 100), 1) if total_pts > 0 else 0.0

            resumen_total_puntos += total_pts
            resumen_total_completados += completados

            rutas_resultado.append({
                "id": ruta_id,
                "camion_asignado": ruta.get("camion_asignado", ""),
                "chofer_asignado": ruta.get("chofer_asignado", ""),
                "ayudante_asignado": ruta.get("ayudante_asignado", ""),
                "estado": ruta.get("estado", "Pendiente"),
                "puntos_estado": puntos_estado,
                "total_puntos": total_pts,
                "puntos_completados": completados,
                "porcentaje_avance": porcentaje
            })

        # ── 6. Resumen global ────────────────────────────────────────────────
        en_espera_global = resumen_total_puntos - resumen_total_completados
        porcentaje_global = (
            round(resumen_total_completados / resumen_total_puntos * 100, 1)
            if resumen_total_puntos > 0 else 0.0
        )

        return {
            "fecha": fecha_hoy,
            "rutas": rutas_resultado,
            "resumen": {
                "total_rutas": len(rutas_resultado),
                "total_puntos": resumen_total_puntos,
                "total_completados": resumen_total_completados,
                "total_en_espera": en_espera_global,
                "porcentaje_global": porcentaje_global
            }
        }

    except Exception as e:
        return {"error": f"Error al obtener dashboard: {str(e)}"}
