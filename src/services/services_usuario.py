import json
import os
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

# Inicializar hasher de contraseñas
ph = PasswordHasher()
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


def _usuario_existe(correo: str) -> bool:
    """Verifica si un usuario ya existe por correo"""
    _inicializar_data_json()
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    return any(usuario["correo"] == correo for usuario in data["usuarios"])


def services_crear_usuario(nombre: str, apellido: str, correo: str, rol: str, contraseña: str, estado: str = "Activo"):
    """Crea un nuevo usuario con contraseña hasheada"""
    try:
        _inicializar_data_json()
        
        # Validar que el usuario no exista
        if _usuario_existe(correo):
            return {"error": "El correo ya está registrado"}
        
        # Hashear contraseña
        contraseña_hasheada = ph.hash(contraseña)
        
        proximo_id = _obtener_proximo_id("usuarios")
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        nuevo_usuario = {
            "id": proximo_id,
            "nombre": nombre,
            "apellido": apellido,
            "correo": correo,
            "rol": rol,
            "contraseña": contraseña_hasheada,
            "estado": estado
        }
        
        data["usuarios"].append(nuevo_usuario)
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {
            "mensaje": "Usuario creado correctamente",
            "usuario": {
                "id": proximo_id,
                "nombre": nombre,
                "apellido": apellido,
                "correo": correo,
                "rol": rol,
                "estado": estado
            }
        }
    except Exception as e:
        return {"error": f"Error al crear usuario: {str(e)}"}


def services_leer_usuario(correo: str):
    """Lee un usuario por correo (sin mostrar contraseña)"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        for usuario in data["usuarios"]:
            if usuario["correo"] == correo:
                return {
                    "usuario": {
                        "id": usuario.get("id"),
                        "nombre": usuario["nombre"],
                        "apellido": usuario.get("apellido", ""),
                        "correo": usuario["correo"],
                        "rol": usuario.get("rol", ""),
                        "estado": usuario.get("estado", "Activo")
                    }
                }
        
        return {"error": "Usuario no encontrado"}
    except Exception as e:
        return {"error": f"Error al leer usuario: {str(e)}"}


def services_actualizar_usuario(correo: str, nombre: str = None, apellido: str = None, rol: str = None, estado: str = None):
    """Actualiza datos de un usuario"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        usuario_encontrado = False
        for usuario in data["usuarios"]:
            if usuario["correo"] == correo:
                if nombre:
                    usuario["nombre"] = nombre
                if apellido:
                    usuario["apellido"] = apellido
                if rol:
                    usuario["rol"] = rol
                if estado:
                    usuario["estado"] = estado
                usuario_encontrado = True
                break
        
        if not usuario_encontrado:
            return {"error": "Usuario no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Usuario actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar usuario: {str(e)}"}


def services_inicio_de_sesion(correo: str, contraseña: str):
    """Valida correo y contraseña para login"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        for usuario in data["usuarios"]:
            if usuario["correo"] == correo:
                try:
                    # Verificar contraseña hasheada
                    ph.verify(usuario["contraseña"], contraseña)
                    # Si llega aquí, contraseña es correcta
                    return {
                        "mensaje": "Sesión iniciada correctamente",
                        "usuario": {
                            "id": usuario.get("id"),
                            "nombre": usuario["nombre"],
                            "apellido": usuario.get("apellido", ""),
                            "correo": usuario["correo"],
                            "rol": usuario.get("rol", ""),
                            "estado": usuario.get("estado", "Activo")
                        }
                    }
                except VerifyMismatchError:
                    return {"error": "Contraseña incorrecta"}
        
        return {"error": "Correo no encontrado"}
    except Exception as e:
        return {"error": f"Error al iniciar sesión: {str(e)}"}


def services_eliminar_usuario(correo: str):
    """Elimina un usuario por correo"""
    try:
        _inicializar_data_json()
        
        with open(DATA_FILE, "r") as f:
            data = json.load(f)
        
        usuario_encontrado = False
        for i, usuario in enumerate(data["usuarios"]):
            if usuario["correo"] == correo:
                del data["usuarios"][i]
                usuario_encontrado = True
                break
        
        if not usuario_encontrado:
            return {"error": "Usuario no encontrado"}
        
        with open(DATA_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        return {"mensaje": "Usuario eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar usuario: {str(e)}"}