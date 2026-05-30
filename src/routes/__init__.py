from .routes_usuarios import router as usuarios_router
from .routes_camion import router as camion_router
from .routes_punto import router as punto_router
from .routes_ruta import router as ruta_router

__all__ = ["usuarios_router", "camion_router", "punto_router", "ruta_router"]
