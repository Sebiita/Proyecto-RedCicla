from data.database import db, fichas_ref, rutas_ref
from models.ficha import ESTADOS_VALIDOS
from datetime import datetime, timezone, timedelta


# Zona horaria de Chile (UTC-4)
CHILE_TZ = timezone(timedelta(hours=-4))


def _generar_timestamp():
    """Genera un timestamp ISO 8601 con zona horaria de Chile"""
    return datetime.now(CHILE_TZ).isoformat()


def services_crear_ficha(ruta_id: str, punto_id: str, kilos_recogidos: float,
                         observaciones: str = "", foto_antes_url: str = "",
                         foto_despues_url: str = "", timestamp: str = None):
    """
    Crea una ficha de recolección en Firestore.
    1. Guarda el documento en la colección 'fichas_realizadas' con estado "recibida"
    2. Actualiza el estado del punto a 'completado' en la ruta correspondiente
    """
    try:
        # Construir el diccionario de la ficha
        nueva_ficha = {
            "ruta_id": ruta_id,
            "punto_id": punto_id,
            "kilos_recogidos": kilos_recogidos,
            "observaciones": observaciones,
            "foto_antes_url": foto_antes_url,
            "foto_despues_url": foto_despues_url,
            "timestamp": timestamp or _generar_timestamp(),
            "estado": "recibida"  # Estado inicial al llegar al servidor
        }

        # 1. Guardar en la colección fichas_realizadas (Firestore genera el ID)
        doc_ref = fichas_ref.document()
        doc_ref.set(nueva_ficha)

        # 2. Actualizar el estado del punto en la ruta
        #    Como los puntos están guardados como array en el documento de la ruta,
        #    leemos la ruta, buscamos el punto y actualizamos su estado
        _actualizar_estado_punto_en_ruta(ruta_id, punto_id)

        return {
            "mensaje": "Ficha creada correctamente",
            "ficha": {
                **nueva_ficha,
                "id": doc_ref.id
            }
        }
    except Exception as e:
        return {"error": f"Error al crear ficha: {str(e)}"}


def _actualizar_estado_punto_en_ruta(ruta_id: str, punto_id: str):
    """
    Actualiza el estado de un punto específico a 'completado' 
    dentro del array de puntos de una ruta.
    """
    try:
        ruta_ref = rutas_ref.document(ruta_id)
        ruta_doc = ruta_ref.get()

        if not ruta_doc.exists:
            print(f"Advertencia: Ruta '{ruta_id}' no encontrada para actualizar punto")
            return

        ruta_data = ruta_doc.to_dict()
        puntos = ruta_data.get("puntos", [])

        # Buscar el punto en el array y actualizar su estado
        punto_actualizado = False
        for i, punto in enumerate(puntos):
            if isinstance(punto, dict) and punto.get("id") == punto_id:
                puntos[i]["estado"] = "completado"
                punto_actualizado = True
                break

        if punto_actualizado:
            ruta_ref.update({"puntos": puntos})
        else:
            print(f"Advertencia: Punto '{punto_id}' no encontrado en ruta '{ruta_id}'")

    except Exception as e:
        print(f"Error al actualizar estado del punto: {str(e)}")


def services_leer_ficha(ficha_id: str):
    """Lee una ficha por su ID"""
    try:
        ficha = fichas_ref.document(ficha_id).get()

        if not ficha.exists:
            return {"error": "Ficha no encontrada"}

        ficha_data = ficha.to_dict()
        ficha_data["id"] = ficha.id
        return {"ficha": ficha_data}
    except Exception as e:
        return {"error": f"Error al leer ficha: {str(e)}"}


def services_leer_fichas_por_ruta(ruta_id: str):
    """Lee todas las fichas asociadas a una ruta específica"""
    try:
        fichas = []
        # Consulta: filtrar fichas donde ruta_id == ruta_id dado
        docs = fichas_ref.where("ruta_id", "==", ruta_id).stream()

        for doc in docs:
            ficha_data = doc.to_dict()
            ficha_data["id"] = doc.id
            fichas.append(ficha_data)

        return {"fichas": fichas, "total": len(fichas)}
    except Exception as e:
        return {"error": f"Error al leer fichas por ruta: {str(e)}"}


def services_leer_todas_fichas():
    """Lee todas las fichas realizadas"""
    try:
        fichas = []
        docs = fichas_ref.stream()

        for doc in docs:
            ficha_data = doc.to_dict()
            ficha_data["id"] = doc.id
            fichas.append(ficha_data)

        return {"fichas": fichas, "total": len(fichas)}
    except Exception as e:
        return {"error": f"Error al leer fichas: {str(e)}"}


def services_actualizar_estado_ficha(ficha_id: str, nuevo_estado: str):
    """
    Cambia el estado de una ficha.
    Estados válidos: recibida → verificada → procesada
                     recibida → rechazada
    
    Ciclo de vida:
    ┌──────────┐    ┌────────────┐    ┌───────────┐
    │ recibida │───►│ verificada │───►│ procesada │
    └──────────┘    └────────────┘    └───────────┘
         │
         └──────────────────────────►┌───────────┐
                                     │ rechazada │
                                     └───────────┘
    """
    try:
        # Validar que el estado sea válido
        if nuevo_estado not in ESTADOS_VALIDOS:
            return {
                "error": f"Estado '{nuevo_estado}' no válido. "
                         f"Estados posibles: {', '.join(ESTADOS_VALIDOS)}"
            }

        ficha_ref = fichas_ref.document(ficha_id)
        ficha_doc = ficha_ref.get()

        if not ficha_doc.exists:
            return {"error": "Ficha no encontrada"}

        ficha_data = ficha_doc.to_dict()
        estado_actual = ficha_data.get("estado", "recibida")

        # Validar transiciones de estado permitidas
        transiciones_permitidas = {
            "recibida": ["verificada", "rechazada"],
            "verificada": ["procesada", "rechazada"],
            "procesada": [],      # Estado final, no se puede cambiar
            "rechazada": ["recibida"],  # Se puede volver a recibida para re-evaluar
        }

        if nuevo_estado not in transiciones_permitidas.get(estado_actual, []):
            return {
                "error": f"No se puede cambiar de '{estado_actual}' a '{nuevo_estado}'. "
                         f"Transiciones permitidas: {transiciones_permitidas.get(estado_actual, [])}"
            }

        # Actualizar el estado
        ficha_ref.update({
            "estado": nuevo_estado,
            "estado_actualizado_en": _generar_timestamp()
        })

        return {
            "mensaje": f"Estado actualizado: {estado_actual} → {nuevo_estado}",
            "ficha_id": ficha_id,
            "estado_anterior": estado_actual,
            "estado_nuevo": nuevo_estado
        }
    except Exception as e:
        return {"error": f"Error al actualizar estado: {str(e)}"}


def services_leer_fichas_por_estado(estado: str):
    """Lee todas las fichas con un estado específico (para panel de admin)"""
    try:
        if estado not in ESTADOS_VALIDOS:
            return {
                "error": f"Estado '{estado}' no válido. "
                         f"Estados posibles: {', '.join(ESTADOS_VALIDOS)}"
            }

        fichas = []
        docs = fichas_ref.where("estado", "==", estado).stream()

        for doc in docs:
            ficha_data = doc.to_dict()
            ficha_data["id"] = doc.id
            fichas.append(ficha_data)

        return {"fichas": fichas, "total": len(fichas), "estado_filtrado": estado}
    except Exception as e:
        return {"error": f"Error al leer fichas por estado: {str(e)}"}


def services_sincronizar_fichas(fichas: list):
    """
    Recibe una lista de fichas (desde la app offline) y las guarda
    todas en Firestore usando un batch write para eficiencia.
    Retorna las fichas creadas con sus IDs generados.
    """
    try:
        if not fichas:
            return {"error": "La lista de fichas está vacía"}

        batch = db.batch()
        fichas_creadas = []

        for ficha_data in fichas:
            # Asegurar que tenga timestamp
            if not ficha_data.get("timestamp"):
                ficha_data["timestamp"] = _generar_timestamp()

            # Crear referencia con ID auto-generado
            doc_ref = fichas_ref.document()

            # Construir el diccionario para Firestore
            ficha_dict = {
                "ruta_id": ficha_data["ruta_id"],
                "punto_id": ficha_data["punto_id"],
                "kilos_recogidos": ficha_data["kilos_recogidos"],
                "observaciones": ficha_data.get("observaciones", ""),
                "foto_antes_url": ficha_data.get("foto_antes_url", ""),
                "foto_despues_url": ficha_data.get("foto_despues_url", ""),
                "timestamp": ficha_data["timestamp"],
                "estado": "recibida"  # Todas llegan como "recibida"
            }

            batch.set(doc_ref, ficha_dict)
            fichas_creadas.append({**ficha_dict, "id": doc_ref.id})

        # Ejecutar el batch (Firestore permite hasta 500 operaciones por batch)
        batch.commit()

        # Actualizar el estado de los puntos en las rutas correspondientes
        for ficha in fichas:
            _actualizar_estado_punto_en_ruta(
                ficha["ruta_id"],
                ficha["punto_id"]
            )

        return {
            "mensaje": f"{len(fichas_creadas)} fichas sincronizadas correctamente",
            "fichas": fichas_creadas,
            "total_sincronizadas": len(fichas_creadas)
        }
    except Exception as e:
        return {"error": f"Error al sincronizar fichas: {str(e)}"}
