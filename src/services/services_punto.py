from data.database import db, puntos_ref


def services_listar_puntos():
    """Lista todos los puntos de reciclaje"""
    try:
        puntos = []
        docs = puntos_ref.stream()
        
        for doc in docs:
            punto_data = doc.to_dict()
            punto_data["id"] = doc.id  # Incluir el ID del documento
            puntos.append(punto_data)
        
        return {"puntos": puntos}
    except Exception as e:
        return {"error": f"Error al listar puntos: {str(e)}"}


def services_crear_punto(municipalidad: str, latitud: float, longitud: float, estado: str = "Activo", 
                        urgencia: str = "Normal", capacidad_maxima: float = 0, capacidad_ocupada: float = 0):
    """Crea un nuevo punto de reciclaje"""
    try:
        nuevo_punto = {
            "municipalidad": municipalidad,
            "latitud": latitud,
            "longitud": longitud,
            "estado": estado,
            "urgencia": urgencia,
            "capacidad_maxima": capacidad_maxima,
            "capacidad_ocupada": capacidad_ocupada
        }
        
        # Firestore genera automáticamente el ID
        doc_ref = puntos_ref.document()
        doc_ref.set(nuevo_punto)
        
        return {
            "mensaje": "Punto de reciclaje creado correctamente",
            "punto": {
                **nuevo_punto,
                "id": doc_ref.id
            }
        }
    except Exception as e:
        return {"error": f"Error al crear punto: {str(e)}"}


def services_leer_punto(punto_id: str):
    """Lee un punto por ID"""
    try:
        punto = puntos_ref.document(punto_id).get()
        
        if not punto.exists:
            return {"error": "Punto no encontrado"}
        
        punto_data = punto.to_dict()
        punto_data["id"] = punto.id
        return {"punto": punto_data}
    except Exception as e:
        return {"error": f"Error al leer punto: {str(e)}"}


def services_actualizar_punto(punto_id: str, municipalidad: str = None, latitud: float = None, 
                             longitud: float = None, estado: str = None, urgencia: str = None,
                             capacidad_maxima: float = None, capacidad_ocupada: float = None):
    """Actualiza datos de un punto de reciclaje"""
    try:
        punto_ref = puntos_ref.document(punto_id)
        
        if not punto_ref.get().exists:
            return {"error": "Punto no encontrado"}
        
        actualizaciones = {}
        if municipalidad:
            actualizaciones["municipalidad"] = municipalidad
        if latitud is not None:
            actualizaciones["latitud"] = latitud
        if longitud is not None:
            actualizaciones["longitud"] = longitud
        if estado:
            actualizaciones["estado"] = estado
        if urgencia:
            actualizaciones["urgencia"] = urgencia
        if capacidad_maxima is not None:
            actualizaciones["capacidad_maxima"] = capacidad_maxima
        if capacidad_ocupada is not None:
            actualizaciones["capacidad_ocupada"] = capacidad_ocupada
        
        if actualizaciones:
            punto_ref.update(actualizaciones)
        
        return {"mensaje": "Punto actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar punto: {str(e)}"}


def services_eliminar_punto(punto_id: str):
    """Elimina un punto de reciclaje por ID"""
    try:
        punto_ref = puntos_ref.document(punto_id)
        
        if not punto_ref.get().exists:
            return {"error": "Punto no encontrado"}
        
        punto_ref.delete()
        
        return {"mensaje": "Punto eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar punto: {str(e)}"}