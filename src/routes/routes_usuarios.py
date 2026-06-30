from fastapi import APIRouter
from models.usuario import (
    UsuarioActualizar,
    UsuarioCrear,
    UsuarioEliminar,
    UsuarioLogin,
)
from services.services_usuario import (
    services_actualizar_usuario,
    services_crear_usuario,
    services_eliminar_usuario,
    services_inicio_de_sesion,
    services_leer_todos_usuarios,
    services_leer_usuario,
)
from auth.security import crear_token_acceso

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.post("/registrar")
def rourtes_crear_usuario(usuario: UsuarioCrear):
    return services_crear_usuario(
        usuario.nombre,
        usuario.apellido,
        usuario.correo,
        usuario.rol,
        usuario.contraseña,
        usuario.estado,
    )


@router.get("/obtener")
def routes_leer_todos_usuarios():
    return services_leer_todos_usuarios()


@router.get("/obtener/{correo}")
def routes_leer_usuario(correo: str):
    return services_leer_usuario(correo)


@router.put("/actualizar/{correo}")
def routes_actualizar_usuario(correo: str, usuario: UsuarioActualizar):
    return services_actualizar_usuario(
        correo,
        usuario.nombre,
        usuario.apellido,
        usuario.rol,
        usuario.estado,
    )


@router.post("/login")
def routes_incio_de_sesion(credenciales: UsuarioLogin):
    resultado = services_inicio_de_sesion(
        credenciales.correo, credenciales.contraseña
    )

    if "error" in resultado:
        return resultado

    usuario = resultado.get("usuario", {})
    correo = usuario.get("correo")
    rol = usuario.get("rol", "")

    access_token = crear_token_acceso(correo, rol)

    return {
        "mensaje": "Sesión iniciada correctamente",
        "access_token": access_token,
        "token_type": "bearer",
        "usuario": usuario,
    }


@router.delete("/eliminar")
def routes_eliminar_usuario(datos: UsuarioEliminar):
    return services_eliminar_usuario(datos.correo)
