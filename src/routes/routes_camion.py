from fastapi import APIRouter
from models.camion import CamionCrear, CamionActualizar
from services.services_camion import (
    services_crear_camion,
    services_leer_todos_camiones,
    services_leer_camion,
    services_actualizar_camion,
    services_eliminar_camion
)

router = APIRouter(prefix="/camiones", tags=["camiones"])


@router.post("/registrar")
def crear_camion(camion: CamionCrear):
    return services_crear_camion(camion.patente, camion.capacidad, camion.estado_mantencion)


@router.get("/obtener")
def leer_todos_camiones():
    return services_leer_todos_camiones()


@router.get("/obtener/{patente}")
def leer_camion(patente: str):
    return services_leer_camion(patente)


@router.put("/actualizar/{patente}")
def actualizar_camion(patente: str, camion: CamionActualizar):
    return services_actualizar_camion(patente, camion.capacidad, camion.estado_mantencion)


@router.delete("/eliminar/{patente}")
def eliminar_camion(patente: str):
    return services_eliminar_camion(patente)
