import json
import os
from datetime import date

DATA_FILE = "data/data.json"


def _inicializar_data_json():
    """Inicializa data.json si no existe"""
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, "w") as f:
            json.dump({"usuarios": [], "camiones": [], "puntos": [], "rutas": []}, f, indent=4)


def _obtener_proximo_id(seccion: str) -> int:
    """Obtiene el próximo ID disponible para una sección"""
    _inicializar_data_json()
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    if data.get(seccion, []):
        return max(item.get("id", 0) for item in data[seccion]) + 1
    return 1


def services_crear_ruta(fecha: str, camion_asignado: str, chofer_asignado: int, 
                       ayudante_asignado: int, puntos: list, estado: str = "Pendiente"):
    """Crea una nueva ruta"""
    try:
        _inicializar_data_json()
        
        proximo_id = _obtener_proximo_id("rutas")
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        nueva_ruta = {
            "id": proximo_id,
            "fecha": fecha,
            "camion_asignado": camion_asignado,
            "chofer_asignado": chofer_asignado,
            "ayudante_asignado": ayudante_asignado,
            "puntos": puntos,
            "estado": estado
        }
        
        data["rutas"].append(nueva_ruta)
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {
            "mensaje": "Ruta creada correctamente",
            "ruta": nueva_ruta
        }
    except Exception as e:
        return {"error": f"Error al crear ruta: {str(e)}"}


def services_leer_ruta(ruta_id: int):
    """Lee una ruta por ID"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        for ruta in data.get("rutas", []):
            if ruta["id"] == ruta_id:
                return {"ruta": ruta}
        
        return {"error": "Ruta no encontrada"}
    except Exception as e:
        return {"error": f"Error al leer ruta: {str(e)}"}


def services_actualizar_ruta(ruta_id: int, fecha: str = None, camion_asignado: str = None,
                            chofer_asignado: int = None, ayudante_asignado: int = None,
                            puntos: list = None, estado: str = None):
    """Actualiza datos de una ruta"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        ruta_encontrada = False
        for ruta in data.get("rutas", []):
            if ruta["id"] == ruta_id:
                if fecha:
                    ruta["fecha"] = fecha
                if camion_asignado:
                    ruta["camion_asignado"] = camion_asignado
                if chofer_asignado is not None:
                    ruta["chofer_asignado"] = chofer_asignado
                if ayudante_asignado is not None:
                    ruta["ayudante_asignado"] = ayudante_asignado
                if puntos is not None:
                    ruta["puntos"] = puntos
                if estado:
                    ruta["estado"] = estado
                ruta_encontrada = True
                break
        
        if not ruta_encontrada:
            return {"error": "Ruta no encontrada"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Ruta actualizada correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar ruta: {str(e)}"}


def services_eliminar_ruta(ruta_id: int):
    """Elimina una ruta por ID"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        ruta_encontrada = False
        for i, ruta in enumerate(data.get("rutas", [])):
            if ruta["id"] == ruta_id:
                del data["rutas"][i]
                ruta_encontrada = True
                break
        
        if not ruta_encontrada:
            return {"error": "Ruta no encontrada"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Ruta eliminada correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar ruta: {str(e)}"}