from .usuario import UsuarioBase, UsuarioCrear, UsuarioRespuesta, UsuarioLogin, UsuarioEliminar, UsuarioActualizar
from .camion import CamionBase, CamionCrear, CamionActualizar, CamionRespuesta, CamionRegistroPeso
from .punto import PuntoRecicljeBase, PuntoRecicljeCrear, PuntoRecicljeActualizar, PuntoRecicljeRespuesta
from .ruta import RutaBase, RutaCrear, RutaActualizar, RutaRespuesta

__all__ = [
    # Usuario
    "UsuarioBase", "UsuarioCrear", "UsuarioRespuesta", "UsuarioLogin", "UsuarioEliminar", "UsuarioActualizar",
    # Camión
    "CamionBase", "CamionCrear", "CamionActualizar", "CamionRespuesta", "CamionRegistroPeso",
    # Punto Reciclaje
    "PuntoRecicljeBase", "PuntoRecicljeCrear", "PuntoRecicljeActualizar", "PuntoRecicljeRespuesta",
    # Ruta
    "RutaBase", "RutaCrear", "RutaActualizar", "RutaRespuesta"
]
