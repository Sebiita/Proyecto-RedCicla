from data.database import db, camiones_ref


def _camion_existe(patente: str) -> bool:
    """Verifica si un camión ya existe por patente"""
    try:
        camion = camiones_ref.document(patente).get()
        return camion.exists
    except Exception as e:
        print(f"Error verificando si camión existe: {str(e)}")
        return False


def services_crear_camion(patente: str, capacidad: float, estado_mantencion: str = "Operativo"):
    """Crea un nuevo camión"""
    try:
        if _camion_existe(patente):
            return {"error": "El camión con esa patente ya existe"}
        
        nuevo_camion = {
            "patente": patente,
            "capacidad": capacidad,
            "estado_mantencion": estado_mantencion
        }
        
        # Usar la patente como documento ID
        camiones_ref.document(patente).set(nuevo_camion)
        
        return {
            "mensaje": "Camión creado correctamente",
            "camion": nuevo_camion
        }
    except Exception as e:
        return {"error": f"Error al crear camión: {str(e)}"}


def services_leer_todos_camiones():
    """Lee todos los camiones"""
    try:
        camiones = []
        docs = camiones_ref.stream()
        
        for doc in docs:
            camiones.append(doc.to_dict())
        
        return {"camiones": camiones}
    except Exception as e:
        return {"error": f"Error al leer camiones: {str(e)}"}


def services_leer_camion(patente: str):
    """Lee un camión por patente"""
    try:
        camion = camiones_ref.document(patente).get()
        
        if not camion.exists:
            return {"error": "Camión no encontrado"}
        
        return {"camion": camion.to_dict()}
    except Exception as e:
        return {"error": f"Error al leer camión: {str(e)}"}


def services_actualizar_camion(patente: str, capacidad: float = None, estado_mantencion: str = None):
    """Actualiza datos de un camión"""
    try:
        camion_ref = camiones_ref.document(patente)
        
        if not camion_ref.get().exists:
            return {"error": "Camión no encontrado"}
        
        actualizaciones = {}
        if capacidad is not None:
            actualizaciones["capacidad"] = capacidad
        if estado_mantencion:
            actualizaciones["estado_mantencion"] = estado_mantencion
        
        if actualizaciones:
            camion_ref.update(actualizaciones)
        
        return {"mensaje": "Camión actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar camión: {str(e)}"}


def services_eliminar_camion(patente: str):
    """Elimina un camión por patente"""
    try:
        camion_ref = camiones_ref.document(patente)
        
        if not camion_ref.get().exists:
            return {"error": "Camión no encontrado"}
        
        camion_ref.delete()
        
        return {"mensaje": "Camión eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar camión: {str(e)}"}


def services_obtener_camiones_en_ruta():
    """Obtiene los camiones disponibles (en ruta / retorno).
    Actualmente retorna todos los camiones registrados."""
    try:
        camiones = []
        docs = camiones_ref.stream()
        for doc in docs:
            camion_data = doc.to_dict()
            camion_data["patente"] = doc.id
            camiones.append(camion_data)
        return {"camiones": camiones}
    except Exception as e:
        return {"error": f"Error al obtener camiones en ruta: {str(e)}"}


def services_registrar_peso(patente: str, peso_bruto: float):
    """Registra el peso bruto de un camión en la subcolección registros_diarios.
    Usa la fecha actual como ID del documento (un registro por día)."""
    try:
        camion_ref = camiones_ref.document(patente)

        if not camion_ref.get().exists:
            return {"error": "Camión no encontrado"}

        from datetime import datetime, timezone

        ahora = datetime.now(timezone.utc)
        fecha_id = ahora.strftime("%Y-%m-%d")

        registro = {
            "peso_bruto": peso_bruto,
            "fecha": fecha_id,
            "timestamp": ahora.isoformat()
        }

        # Guardar en subcolección registros_diarios del camión
        camion_ref.collection("registros_diarios").document(fecha_id).set(registro)

        return {
            "mensaje": "Peso bruto registrado correctamente",
            "registro": registro
        }
    except Exception as e:
        return {"error": f"Error al registrar peso: {str(e)}"}


def services_leer_camiones_completo():
    """Lee todos los camiones con sus registros diarios (subcolecciones).
    Útil para verificar que los datos de peso se almacenan correctamente."""
    try:
        camiones = []
        docs = camiones_ref.stream()

        for doc in docs:
            camion_data = doc.to_dict()
            camion_data["patente"] = doc.id

            # Leer subcolección registros_diarios
            registros = []
            registros_docs = camiones_ref.document(doc.id).collection("registros_diarios").stream()
            for reg_doc in registros_docs:
                reg_data = reg_doc.to_dict()
                reg_data["id"] = reg_doc.id
                registros.append(reg_data)

            camion_data["registros_diarios"] = registros
            camiones.append(camion_data)

        return {"camiones": camiones, "total": len(camiones)}
    except Exception as e:
        return {"error": f"Error al leer camiones completos: {str(e)}"}