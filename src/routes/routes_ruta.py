from fastapi import APIRouter
from models.ruta import RutaCrear, RutaActualizar
from services.services_ruta import (
    services_crear_ruta,
    services_leer_ruta,
    services_leer_todas_rutas,
    services_actualizar_ruta,
    services_eliminar_ruta
)

router = APIRouter(prefix="/rutas", tags=["rutas"])


@router.post("/registrar")
def crear_ruta(ruta: RutaCrear):
    return services_crear_ruta(ruta.fecha.isoformat(), ruta.camion_asignado,
                              ruta.chofer_asignado, ruta.ayudante_asignado,
                              ruta.puntos, ruta.estado)


@router.get("/listar")
def listar_rutas():
    """Lista todas las rutas"""
    return services_leer_todas_rutas()


@router.get("/obtener/{ruta_id}")
def leer_ruta(ruta_id: str):
    return services_leer_ruta(ruta_id)


@router.put("/actualizar/{ruta_id}")
def actualizar_ruta(ruta_id: str, ruta: RutaActualizar):
    fecha_str = ruta.fecha.isoformat() if ruta.fecha else None
    return services_actualizar_ruta(ruta_id, fecha_str, ruta.camion_asignado,
                                   ruta.chofer_asignado, ruta.ayudante_asignado,
                                   ruta.puntos, ruta.estado)


@router.delete("/eliminar/{ruta_id}")
def eliminar_ruta(ruta_id: str):
    return services_eliminar_ruta(ruta_id)
