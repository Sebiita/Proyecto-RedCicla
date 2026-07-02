from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import date


class ReporteFiltro(BaseModel):
    """Filtros opcionales para el reporte de rendimiento"""
    fecha_inicio: Optional[date] = Field(
        default=None,
        description="Fecha de inicio del período (YYYY-MM-DD)"
    )
    fecha_fin: Optional[date] = Field(
        default=None,
        description="Fecha de término del período (YYYY-MM-DD)"
    )
    camion_asignado: Optional[str] = Field(
        default=None,
        description="Patente del camión a filtrar"
    )
    chofer_asignado: Optional[str] = Field(
        default=None,
        description="Correo del chofer a filtrar"
    )


class RendimientoCamion(BaseModel):
    """Métricas de rendimiento para un camión"""
    patente: str
    capacidad: float
    kilos_recogidos: float
    rendimiento: float = Field(
        ...,
        description="Kilos recolectados dividido por la capacidad del camión"
    )
    rutas_asignadas: int


class EficienciaConductor(BaseModel):
    """Métricas de eficiencia para un conductor"""
    chofer_email: str
    rutas_realizadas: int
    kilos_recogidos: float
    peso_promedio_por_ruta: float


class ReporteRendimiento(BaseModel):
    """Reporte completo de rendimiento"""
    fecha_inicio: Optional[str]
    fecha_fin: Optional[str]
    total_rutas: int
    rutas_por_estado: Dict[str, int]
    peso_total_recogido_kg: float
    peso_promedio_por_ruta_kg: float
    tiempo_total_horas: float
    tiempo_promedio_por_ruta_horas: float
    distancia_total_km: float
    distancia_promedio_por_ruta_km: float
    eficiencia_kg_por_km: float
    rendimiento_por_camion: List[RendimientoCamion]
    eficiencia_por_conductor: List[EficienciaConductor]
