import json
import os
from pathlib import Path

# Path absoluto al archivo data.json dentro de src/data
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_FILE = str(BASE_DIR / 'data' / 'data.json')


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


def services_listar_puntos():
    """Lista todos los puntos de reciclaje"""
    try:
        _inicializar_data_json()
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        return {"puntos": data.get("puntos", [])}
    except Exception as e:
        return {"error": f"Error al listar puntos: {str(e)}"}


def services_crear_punto(municipalidad: str, latitud: float, longitud: float, estado: str = "Activo", 
                        urgencia: str = "Normal", capacidad_maxima: float = 0, capacidad_ocupada: float = 0):
    """Crea un nuevo punto de reciclaje"""
    try:
        _inicializar_data_json()
        
        proximo_id = _obtener_proximo_id("puntos")
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        nuevo_punto = {
            "id": proximo_id,
            "municipalidad": municipalidad,
            "latitud": latitud,
            "longitud": longitud,
            "estado": estado,
            "urgencia": urgencia,
            "capacidad_maxima": capacidad_maxima,
            "capacidad_ocupada": capacidad_ocupada
        }
        
        data["puntos"].append(nuevo_punto)
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {
            "mensaje": "Punto de reciclaje creado correctamente",
            "punto": nuevo_punto
        }
    except Exception as e:
        return {"error": f"Error al crear punto: {str(e)}"}


def services_leer_punto(punto_id: int):
    """Lee un punto por ID"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        for punto in data.get("puntos", []):
            if punto["id"] == punto_id:
                return {"punto": punto}
        
        return {"error": "Punto no encontrado"}
    except Exception as e:
        return {"error": f"Error al leer punto: {str(e)}"}


def services_actualizar_punto(punto_id: int, municipalidad: str = None, latitud: float = None, 
                             longitud: float = None, estado: str = None, urgencia: str = None,
                             capacidad_maxima: float = None, capacidad_ocupada: float = None):
    """Actualiza datos de un punto de reciclaje"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        punto_encontrado = False
        for punto in data.get("puntos", []):
            if punto["id"] == punto_id:
                if municipalidad:
                    punto["municipalidad"] = municipalidad
                if latitud is not None:
                    punto["latitud"] = latitud
                if longitud is not None:
                    punto["longitud"] = longitud
                if estado:
                    punto["estado"] = estado
                if urgencia:
                    punto["urgencia"] = urgencia
                if capacidad_maxima is not None:
                    punto["capacidad_maxima"] = capacidad_maxima
                if capacidad_ocupada is not None:
                    punto["capacidad_ocupada"] = capacidad_ocupada
                punto_encontrado = True
                break
        
        if not punto_encontrado:
            return {"error": "Punto no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Punto actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar punto: {str(e)}"}


def services_eliminar_punto(punto_id: int):
    """Elimina un punto de reciclaje por ID"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        punto_encontrado = False
        for i, punto in enumerate(data.get("puntos", [])):
            if punto["id"] == punto_id:
                del data["puntos"][i]
                punto_encontrado = True
                break
        
        if not punto_encontrado:
            return {"error": "Punto no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Punto eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar punto: {str(e)}"}