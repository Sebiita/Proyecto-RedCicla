from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from datetime import date
from models.reporte import ReporteRendimiento
from services.services_reportes import services_generar_reporte_rendimiento

router = APIRouter(prefix="/reportes", tags=["reportes"])


@router.get("/rendimiento", response_model=ReporteRendimiento)
def generar_reporte_rendimiento(
    fecha_inicio: Optional[date] = Query(
        None,
        description="Fecha de inicio del período (YYYY-MM-DD)"
    ),
    fecha_fin: Optional[date] = Query(
        None,
        description="Fecha de término del período (YYYY-MM-DD)"
    ),
    camion_asignado: Optional[str] = Query(
        None,
        description="Patente del camión para filtrar"
    ),
    chofer_asignado: Optional[str] = Query(
        None,
        description="Correo del chofer para filtrar"
    )
):
    """
    Genera el reporte de rendimiento agregando rutas, fichas de recolección
    y datos de camiones. Permite filtrar por período, camión y/o chofer.
    """
    # Validación básica de rango de fechas
    if fecha_inicio and fecha_fin and fecha_inicio > fecha_fin:
        raise HTTPException(
            status_code=400,
            detail="La fecha de inicio no puede ser mayor a la fecha de fin"
        )

    fecha_inicio_str = fecha_inicio.isoformat() if fecha_inicio else None
    fecha_fin_str = fecha_fin.isoformat() if fecha_fin else None

    resultado = services_generar_reporte_rendimiento(
        fecha_inicio=fecha_inicio_str,
        fecha_fin=fecha_fin_str,
        camion_asignado=camion_asignado,
        chofer_asignado=chofer_asignado
    )

    if "error" in resultado:
        raise HTTPException(status_code=500, detail=resultado["error"])

    return resultado
