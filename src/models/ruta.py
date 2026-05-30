from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date


class RutaBase(BaseModel):
    """Modelo base para ruta"""
    fecha: date = Field(..., description="Fecha de la ruta")
    camion_asignado: str = Field(..., description="Patente del camión asignado")
    chofer_asignado: int = Field(..., description="ID del usuario chofer asignado")
    ayudante_asignado: int = Field(..., description="ID del usuario ayudante asignado")
    puntos: List[int] = Field(..., description="Lista de IDs de puntos a visitar")
    estado: str = Field(default="Pendiente", description="Estado de la ruta (Pendiente, En curso, Finalizada)")


class RutaCrear(RutaBase):
    """Modelo para crear ruta"""
    pass


class RutaActualizar(BaseModel):
    """Modelo para actualizar ruta"""
    fecha: Optional[date] = None
    camion_asignado: Optional[str] = None
    chofer_asignado: Optional[int] = None
    ayudante_asignado: Optional[int] = None
    puntos: Optional[List[int]] = None
    estado: Optional[str] = None


class RutaRespuesta(RutaBase):
    """Modelo de respuesta para ruta"""
    id: Optional[int] = None
