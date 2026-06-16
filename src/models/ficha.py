from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# Estados posibles de una ficha (ciclo de vida)
# "recibida"   → Llegó al servidor desde la app
# "verificada" → Un administrador revisó y aprobó la ficha
# "procesada"  → Los datos fueron procesados/contabilizados
# "rechazada"  → La ficha fue rechazada por datos inválidos
ESTADOS_VALIDOS = ["recibida", "verificada", "procesada", "rechazada"]


class FichaBase(BaseModel):
    """Modelo base para ficha de recolección"""
    ruta_id: str = Field(..., description="ID de la ruta asociada (llave foránea)")
    punto_id: str = Field(..., description="ID del punto asociado (llave foránea)")
    kilos_recogidos: float = Field(..., gt=0, description="Kilos de vidrio recogidos")
    observaciones: Optional[str] = Field(default="", description="Observaciones del retiro")
    foto_antes_url: Optional[str] = Field(default="", description="URL de la foto antes del retiro")
    foto_despues_url: Optional[str] = Field(default="", description="URL de la foto después del retiro")
    timestamp: Optional[str] = Field(default=None, description="Marca de tiempo ISO 8601")


class FichaCrear(FichaBase):
    """Modelo para crear una ficha de recolección"""
    pass


class FichaRespuesta(FichaBase):
    """Modelo de respuesta para ficha"""
    id: Optional[str] = None
    estado: Optional[str] = Field(default="recibida", description="Estado actual de la ficha")


class FichaActualizarEstado(BaseModel):
    """Modelo para cambiar el estado de una ficha"""
    estado: str = Field(..., description="Nuevo estado: recibida, verificada, procesada, rechazada")


class FichaSincronizar(BaseModel):
    """Modelo para recibir un batch de fichas para sincronización offline"""
    fichas: List[FichaCrear] = Field(..., description="Lista de fichas pendientes por sincronizar")

