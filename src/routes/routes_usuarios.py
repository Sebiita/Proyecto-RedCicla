from fastapi import APIRouter
from models.usuario import UsuarioCrear, UsuarioLogin, UsuarioEliminar, UsuarioActualizar
from services.services_usuario import (
    services_crear_usuario,
    services_leer_usuario,
    services_actualizar_usuario,
    services_inicio_de_sesion,
    services_eliminar_usuario
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.post("/registrar")
def rourtes_crear_usuario(usuario: UsuarioCrear):
    return services_crear_usuario(usuario.nombre, usuario.apellido, usuario.correo, 
                                 usuario.rol, usuario.contraseña, usuario.estado)


@router.get("/obtener/{correo}")
def routes_leer_usuario(correo: str):
    return services_leer_usuario(correo)


@router.put("/actualizar/{correo}")
def routes_actualizar_usuario(correo: str, usuario: UsuarioActualizar):
    return services_actualizar_usuario(correo, usuario.nombre, usuario.apellido, 
                                      usuario.rol, usuario.estado)


@router.post("/login")
def routes_incio_de_sesion(credenciales: UsuarioLogin):
    return services_inicio_de_sesion(credenciales.correo, credenciales.contraseña)


@router.delete("/eliminar")
def routes_eliminar_usuario(datos: UsuarioEliminar):
    return services_eliminar_usuario(datos.correo)





