from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date


class RutaBase(BaseModel):
    """Modelo base para ruta"""
    fecha: date = Field(..., description="Fecha de la ruta")
    camion_asignado: str = Field(..., description="Patente del camión asignado")
    chofer_asignado: str = Field(..., description="Correo del usuario chofer asignado")
    ayudante_asignado: str = Field(..., description="Correo del usuario ayudante asignado")
    puntos: List[str] = Field(..., description="Lista de IDs de puntos a visitar")
    estado: str = Field(default="Pendiente", description="Estado de la ruta (Pendiente, En curso, Finalizada)")
    polyline: Optional[str] = Field(default=None, description="Polyline codificada de Google Maps")
    puntos_ordenados: Optional[List[str]] = Field(default=None, description="Orden optimizado de los IDs de los puntos")


class RutaCrear(RutaBase):
    """Modelo para crear ruta"""

class RutaActualizar(BaseModel):
    """Modelo para actualizar ruta"""
    fecha: Optional[date] = None
    camion_asignado: Optional[str] = None
    chofer_asignado: Optional[str] = None
    ayudante_asignado: Optional[str] = None
    puntos: Optional[List[str]] = None
    estado: Optional[str] = None
    polyline: Optional[str] = None
    puntos_ordenados: Optional[List[str]] = None


class RutaRespuesta(RutaBase):
    """Modelo de respuesta para ruta"""
    id: Optional[str] = None
