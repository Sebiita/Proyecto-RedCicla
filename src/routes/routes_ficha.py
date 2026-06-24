from fastapi import APIRouter
from models.ficha import FichaCrear, FichaSincronizar, FichaActualizarEstado
from services.services_ficha import (
    services_crear_ficha,
    services_leer_ficha,
    services_leer_fichas_por_ruta,
    services_leer_todas_fichas,
    services_sincronizar_fichas,
    services_actualizar_estado_ficha,
    services_leer_fichas_por_estado
)

router = APIRouter(prefix="/fichas", tags=["fichas"])


@router.post("/registrar")
def crear_ficha(ficha: FichaCrear):
    """Crea una ficha de recolección individual (estado inicial: 'recibida')"""
    return services_crear_ficha(
        ruta_id=ficha.ruta_id,
        punto_id=ficha.punto_id,
        kilos_recogidos=ficha.kilos_recogidos,
        observaciones=ficha.observaciones,
        foto_antes_url=ficha.foto_antes_url,
        foto_despues_url=ficha.foto_despues_url,
        timestamp=ficha.timestamp
    )


@router.post("/sincronizar")
def sincronizar_fichas(datos: FichaSincronizar):
    """Recibe un batch de fichas pendientes desde la app (modo offline)"""
    fichas_dict = [ficha.model_dump() for ficha in datos.fichas]
    return services_sincronizar_fichas(fichas_dict)


@router.put("/estado/{ficha_id}")
def actualizar_estado(ficha_id: str, datos: FichaActualizarEstado):
    """
    Cambia el estado de una ficha.
    Transiciones permitidas:
    - recibida → verificada | rechazada
    - verificada → procesada | rechazada
    - rechazada → recibida (re-evaluar)
    - procesada → (estado final)
    """
    return services_actualizar_estado_ficha(ficha_id, datos.estado)


@router.get("/listar")
def listar_fichas():
    """Lista todas las fichas realizadas"""
    return services_leer_todas_fichas()


@router.get("/por-estado/{estado}")
def fichas_por_estado(estado: str):
    """
    Lista fichas filtradas por estado.
    Estados: recibida, verificada, procesada, rechazada
    """
    return services_leer_fichas_por_estado(estado)


@router.get("/por-ruta/{ruta_id}")
def fichas_por_ruta(ruta_id: str):
    """Lista todas las fichas asociadas a una ruta"""
    return services_leer_fichas_por_ruta(ruta_id)


@router.get("/obtener/{ficha_id}")
def obtener_ficha(ficha_id: str):
    """Obtiene una ficha específica por ID"""
    return services_leer_ficha(ficha_id)
