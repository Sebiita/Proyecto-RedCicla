<<<<<<< HEAD
import json
import os
from datetime import date
from pathlib import Path

# Path absoluto al archivo data.json dentro de src/data
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_FILE = str(BASE_DIR / 'data' / 'data.json')
=======
from data.database import db, rutas_ref
>>>>>>> main


def services_crear_ruta(fecha: str, camion_asignado: str, chofer_asignado: str, 
                       ayudante_asignado: str, puntos: list, estado: str = "Pendiente"):
    """Crea una nueva ruta"""
    try:
        nueva_ruta = {
            "fecha": fecha,
            "camion_asignado": camion_asignado,
            "chofer_asignado": chofer_asignado,
            "ayudante_asignado": ayudante_asignado,
            "puntos": puntos,
            "estado": estado
        }
        
        # Firestore genera automáticamente el ID
        doc_ref = rutas_ref.document()
        doc_ref.set(nueva_ruta)
        
        return {
            "mensaje": "Ruta creada correctamente",
            "ruta": {
                **nueva_ruta,
                "id": doc_ref.id
            }
        }
    except Exception as e:
        return {"error": f"Error al crear ruta: {str(e)}"}


def services_leer_ruta(ruta_id: str):
    """Lee una ruta por ID"""
    try:
        ruta = rutas_ref.document(ruta_id).get()
        
        if not ruta.exists:
            return {"error": "Ruta no encontrada"}
        
        ruta_data = ruta.to_dict()
        ruta_data["id"] = ruta.id
        return {"ruta": ruta_data}
    except Exception as e:
        return {"error": f"Error al leer ruta: {str(e)}"}


def services_leer_todas_rutas():
    """Lee todas las rutas"""
    try:
        rutas = []
        docs = rutas_ref.stream()
        
        for doc in docs:
            ruta_data = doc.to_dict()
            ruta_data["id"] = doc.id
            rutas.append(ruta_data)
        
        return {"rutas": rutas}
    except Exception as e:
        return {"error": f"Error al leer rutas: {str(e)}"}


def services_actualizar_ruta(ruta_id: str, fecha: str = None, camion_asignado: str = None,
                            chofer_asignado: str = None, ayudante_asignado: str = None,
                            puntos: list = None, estado: str = None):
    """Actualiza datos de una ruta"""
    try:
        ruta_ref = rutas_ref.document(ruta_id)
        
        if not ruta_ref.get().exists:
            return {"error": "Ruta no encontrada"}
        
        actualizaciones = {}
        if fecha:
            actualizaciones["fecha"] = fecha
        if camion_asignado:
            actualizaciones["camion_asignado"] = camion_asignado
        if chofer_asignado:
            actualizaciones["chofer_asignado"] = chofer_asignado
        if ayudante_asignado:
            actualizaciones["ayudante_asignado"] = ayudante_asignado
        if puntos is not None:
            actualizaciones["puntos"] = puntos
        if estado:
            actualizaciones["estado"] = estado
        
        if actualizaciones:
            ruta_ref.update(actualizaciones)
        
        return {"mensaje": "Ruta actualizada correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar ruta: {str(e)}"}


def services_eliminar_ruta(ruta_id: str):
    """Elimina una ruta por ID"""
    try:
        ruta_ref = rutas_ref.document(ruta_id)
        
        if not ruta_ref.get().exists:
            return {"error": "Ruta no encontrada"}
        
        ruta_ref.delete()
        
        return {"mensaje": "Ruta eliminada correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar ruta: {str(e)}"}