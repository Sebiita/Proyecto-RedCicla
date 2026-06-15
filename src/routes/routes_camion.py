from fastapi import APIRouter
from models.camion import CamionCrear, CamionActualizar, CamionRegistroPeso
from services.services_camion import (
    services_crear_camion,
    services_leer_todos_camiones,
    services_leer_camion,
    services_actualizar_camion,
    services_eliminar_camion,
    services_obtener_camiones_en_ruta,
    services_registrar_peso,
    services_leer_camiones_completo
)

router = APIRouter(prefix="/camiones", tags=["camiones"])


@router.post("/registrar")
def crear_camion(camion: CamionCrear):
    return services_crear_camion(camion.patente, camion.capacidad, camion.estado_mantencion)


@router.get("/obtener")
def leer_todos_camiones():
    return services_leer_todos_camiones()


@router.get("/en_ruta")
def obtener_camiones_en_ruta():
    """Obtiene los camiones en ruta (disponibles para registro de peso en balanza)"""
    return services_obtener_camiones_en_ruta()


@router.get("/completo")
def leer_camiones_completo():
    """Devuelve todos los camiones con sus registros diarios (para verificación)"""
    return services_leer_camiones_completo()


@router.get("/obtener/{patente}")
def leer_camion(patente: str):
    return services_leer_camion(patente)


@router.put("/actualizar/{patente}")
def actualizar_camion(patente: str, camion: CamionActualizar):
    return services_actualizar_camion(patente, camion.capacidad, camion.estado_mantencion)


@router.post("/{patente}/peso")
def registrar_peso(patente: str, datos: CamionRegistroPeso):
    """Registra el peso bruto del camión en balanza (HU-15)"""
    return services_registrar_peso(patente, datos.peso_bruto)


@router.delete("/eliminar/{patente}")
def eliminar_camion(patente: str):
    return services_eliminar_camion(patente)
