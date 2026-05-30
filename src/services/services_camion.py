import json
import os

DATA_FILE = "data/data.json"


def _inicializar_data_json():
    """Inicializa data.json si no existe"""
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, "w") as f:
            json.dump({"usuarios": [], "camiones": [], "puntos": [], "rutas": []}, f, indent=4)


def _camion_existe(patente: str) -> bool:
    """Verifica si un camión ya existe por patente"""
    _inicializar_data_json()
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    return any(camion["patente"] == patente for camion in data.get("camiones", []))


def services_crear_camion(patente: str, capacidad: float, estado_mantencion: str = "Operativo"):
    """Crea un nuevo camión"""
    try:
        _inicializar_data_json()
        
        if _camion_existe(patente):
            return {"error": "El camión con esa patente ya existe"}
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        nuevo_camion = {
            "patente": patente,
            "capacidad": capacidad,
            "estado_mantencion": estado_mantencion
        }
        
        data["camiones"].append(nuevo_camion)
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {
            "mensaje": "Camión creado correctamente",
            "camion": nuevo_camion
        }
    except Exception as e:
        return {"error": f"Error al crear camión: {str(e)}"}


def services_leer_camion(patente: str):
    """Lee un camión por patente"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        for camion in data.get("camiones", []):
            if camion["patente"] == patente:
                return {"camion": camion}
        
        return {"error": "Camión no encontrado"}
    except Exception as e:
        return {"error": f"Error al leer camión: {str(e)}"}


def services_actualizar_camion(patente: str, capacidad: float = None, estado_mantencion: str = None):
    """Actualiza datos de un camión"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        camion_encontrado = False
        for camion in data.get("camiones", []):
            if camion["patente"] == patente:
                if capacidad is not None:
                    camion["capacidad"] = capacidad
                if estado_mantencion:
                    camion["estado_mantencion"] = estado_mantencion
                camion_encontrado = True
                break
        
        if not camion_encontrado:
            return {"error": "Camión no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Camión actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar camión: {str(e)}"}


def services_eliminar_camion(patente: str):
    """Elimina un camión por patente"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        camion_encontrado = False
        for i, camion in enumerate(data.get("camiones", [])):
            if camion["patente"] == patente:
                del data["camiones"][i]
                camion_encontrado = True
                break
        
        if not camion_encontrado:
            return {"error": "Camión no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Camión eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar camión: {str(e)}"}