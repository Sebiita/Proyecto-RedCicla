from fastapi import APIRouter
from models.punto import PuntoRecicljeCrear, PuntoRecicljeActualizar
from services.services_punto import (
    services_listar_puntos,
    services_crear_punto,
    services_leer_punto,
    services_actualizar_punto,
    services_eliminar_punto
)

router = APIRouter(prefix="/puntos", tags=["puntos"])


@router.post("/registrar")
def crear_punto(punto: PuntoRecicljeCrear):
    return services_crear_punto(punto.municipalidad, punto.latitud, punto.longitud,
                               punto.estado, punto.urgencia, punto.capacidad_maxima,
                               punto.capacidad_ocupada)


@router.get("/obtener")
def listar_puntos():
    return services_listar_puntos()


# ========== NUEVO ENDPOINT PARA EL HOMESCREEN DE FLUTTER ==========
# ========== NUEVO ENDPOINT OPTIMIZADO PARA EL HOMESCREEN DE FLUTTER ==========
@router.get("/api/puntos")
def obtener_nombres_puntos():
    """
    Retorna la lista de puntos estructurada correctamente para que
    la app de Flutter consuma el servicio sin errores de formato.
    """
    # 1. Traemos el diccionario del servicio
    respuesta = services_listar_puntos()
    
    # 2. Si el servicio reportó un error, lo devolvemos de inmediato
    if "error" in respuesta:
        return respuesta

    # 3. Extraemos la lista real de documentos
    todos_los_puntos = respuesta.get("puntos", [])
    
    # 4. Devolvemos la estructura limpia que tus modelos de Flutter esperan leer
    return {"puntos": todos_los_puntos}
@router.get("/obtener/{punto_id}")
def leer_punto(punto_id: str):
    return services_leer_punto(punto_id)


@router.put("/actualizar/{punto_id}")
def actualizar_punto(punto_id: str, punto: PuntoRecicljeActualizar):
    return services_actualizar_punto(punto_id, punto.municipalidad, punto.latitud,
                                    punto.longitud, punto.estado, punto.urgencia,
                                    punto.capacidad_maxima, punto.capacidad_ocupada)


@router.delete("/eliminar/{punto_id}")
def eliminar_punto(punto_id: str):
    return services_eliminar_punto(punto_id)