from pydantic import BaseModel, Field
from typing import Optional


class CamionBase(BaseModel):
    """Modelo base para camión"""
    patente: str = Field(..., min_length=1, max_length=20, description="Patente del camión")
    capacidad: float = Field(..., gt=0, description="Capacidad del camión en m³ o kg")
    estado_mantencion: str = Field(default="Operativo", description="Estado de mantencion (Operativo, Mantencion, Fuera de servicio)")


class CamionCrear(CamionBase):
    """Modelo para crear camión"""
    pass


class CamionActualizar(BaseModel):
    """Modelo para actualizar camión"""
    patente: Optional[str] = Field(None, min_length=1, max_length=20)
    capacidad: Optional[float] = Field(None, gt=0)
    estado_mantencion: Optional[str] = None


class CamionRegistroPeso(BaseModel):
    """Modelo para registrar peso bruto en balanza"""
    peso_bruto: float = Field(..., gt=0, description="Peso bruto del camión en kg registrado en balanza")


class CamionRespuesta(CamionBase):
    """Modelo de respuesta para camión"""
    pass
