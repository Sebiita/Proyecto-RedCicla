<<<<<<< HEAD
import json
import os
from pathlib import Path
=======
>>>>>>> main
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from data.database import db, usuarios_ref

# Inicializar hasher de contraseñas
ph = PasswordHasher()
<<<<<<< HEAD

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
=======
>>>>>>> main


def _usuario_existe(correo: str) -> bool:
    """Verifica si un usuario ya existe por correo"""
    try:
        usuario = usuarios_ref.document(correo).get()
        return usuario.exists
    except Exception as e:
        print(f"Error verificando si usuario existe: {str(e)}")
        return False


def services_crear_usuario(nombre: str, apellido: str, correo: str, rol: str, contraseña: str, estado: str = "Activo"):
    """Crea un nuevo usuario con contraseña hasheada"""
    try:
        # Validar que el usuario no exista
        if _usuario_existe(correo):
            return {"error": "El correo ya está registrado"}
        
        # Hashear contraseña
        contraseña_hasheada = ph.hash(contraseña)
        
        nuevo_usuario = {
            "nombre": nombre,
            "apellido": apellido,
            "correo": correo,
            "rol": rol,
            "contraseña": contraseña_hasheada,
            "estado": estado
        }
        
        # Usar el correo como documento ID
        usuarios_ref.document(correo).set(nuevo_usuario)
        
        return {
            "mensaje": "Usuario creado correctamente",
            "usuario": {
                "nombre": nombre,
                "apellido": apellido,
                "correo": correo,
                "rol": rol,
                "estado": estado
            }
        }
    except Exception as e:
        return {"error": f"Error al crear usuario: {str(e)}"}


def services_leer_todos_usuarios():
    """Lee todos los usuarios (sin mostrar contraseñas)"""
    try:
        usuarios_sin_password = []
        docs = usuarios_ref.stream()
        
        for doc in docs:
            usuario_data = doc.to_dict()
            usuarios_sin_password.append({
                "correo": usuario_data.get("correo"),
                "nombre": usuario_data["nombre"],
                "apellido": usuario_data.get("apellido", ""),
                "rol": usuario_data.get("rol", ""),
                "estado": usuario_data.get("estado", "Activo")
            })
        
        return {"usuarios": usuarios_sin_password}
    except Exception as e:
        return {"error": f"Error al leer usuarios: {str(e)}"}


def services_leer_usuario(correo: str):
    """Lee un usuario por correo (sin mostrar contraseña)"""
    try:
        usuario = usuarios_ref.document(correo).get()
        
        if not usuario.exists:
            return {"error": "Usuario no encontrado"}
        
        usuario_data = usuario.to_dict()
        return {
            "usuario": {
                "correo": usuario_data.get("correo"),
                "nombre": usuario_data["nombre"],
                "apellido": usuario_data.get("apellido", ""),
                "rol": usuario_data.get("rol", ""),
                "estado": usuario_data.get("estado", "Activo")
            }
        }
    except Exception as e:
        return {"error": f"Error al leer usuario: {str(e)}"}


def services_actualizar_usuario(correo: str, nombre: str = None, apellido: str = None, rol: str = None, estado: str = None):
    """Actualiza datos de un usuario"""
    try:
        usuario_ref = usuarios_ref.document(correo)
        
        if not usuario_ref.get().exists:
            return {"error": "Usuario no encontrado"}
        
        actualizaciones = {}
        if nombre:
            actualizaciones["nombre"] = nombre
        if apellido:
            actualizaciones["apellido"] = apellido
        if rol:
            actualizaciones["rol"] = rol
        if estado:
            actualizaciones["estado"] = estado
        
        if actualizaciones:
            usuario_ref.update(actualizaciones)
        
        return {"mensaje": "Usuario actualizado correctamente"}
    except Exception as e:
        return {"error": f"Error al actualizar usuario: {str(e)}"}


def services_inicio_de_sesion(correo: str, contraseña: str):
    """Valida correo y contraseña para login"""
    try:
        usuario_doc = usuarios_ref.document(correo).get()
        
        if not usuario_doc.exists:
            return {"error": "Correo no encontrado"}
        
        usuario_data = usuario_doc.to_dict()
        
        try:
            # Verificar contraseña hasheada
            ph.verify(usuario_data["contraseña"], contraseña)
            # Si llega aquí, contraseña es correcta
            return {
                "mensaje": "Sesión iniciada correctamente",
                "usuario": {
                    "correo": usuario_data.get("correo"),
                    "nombre": usuario_data["nombre"],
                    "apellido": usuario_data.get("apellido", ""),
                    "rol": usuario_data.get("rol", ""),
                    "estado": usuario_data.get("estado", "Activo")
                }
            }
        except VerifyMismatchError:
            return {"error": "Contraseña incorrecta"}
    except Exception as e:
        return {"error": f"Error al iniciar sesión: {str(e)}"}


def services_eliminar_usuario(correo: str):
    """Elimina un usuario por correo"""
    try:
        usuario_ref = usuarios_ref.document(correo)
        
        if not usuario_ref.get().exists:
            return {"error": "Usuario no encontrado"}
        
        usuario_ref.delete()
        
        return {"mensaje": "Usuario eliminado correctamente"}
    except Exception as e:
        return {"error": f"Error al eliminar usuario: {str(e)}"}