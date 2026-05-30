from pydantic import BaseModel, Field
from typing import Optional


class PuntoRecicljeBase(BaseModel):
    """Modelo base para punto de reciclaje"""
    municipalidad: str = Field(..., min_length=1, max_length=100, description="Municipalidad donde está el punto")
    latitud: float = Field(..., description="Latitud de las coordenadas")
    longitud: float = Field(..., description="Longitud de las coordenadas")
    estado: str = Field(default="Activo", description="Estado del punto (Activo, Inactivo, Mantencion)")
    urgencia: str = Field(default="Normal", description="Nivel de urgencia (Baja, Normal, Alta, Crítica)")
    capacidad_maxima: float = Field(..., gt=0, description="Capacidad máxima del punto")
    capacidad_ocupada: float = Field(default=0, ge=0, description="Capacidad ocupada actualmente")


class PuntoRecicljeCrear(PuntoRecicljeBase):
    """Modelo para crear punto de reciclaje"""
    pass


class PuntoRecicljeActualizar(BaseModel):
    """Modelo para actualizar punto de reciclaje"""
    municipalidad: Optional[str] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    estado: Optional[str] = None
    urgencia: Optional[str] = None
    capacidad_maxima: Optional[float] = None
    capacidad_ocupada: Optional[float] = None


class PuntoRecicljeRespuesta(PuntoRecicljeBase):
    """Modelo de respuesta para punto de reciclaje"""
    id: Optional[int] = None
