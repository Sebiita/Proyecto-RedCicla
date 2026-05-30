from fastapi import APIRouter
from models.usuario import UsuarioCrear, UsuarioLogin, UsuarioEliminar
from services.services_usuario import (
    services_crear_usuario,
    services_leer_usuario,
    services_inicio_de_sesion,
    services_eliminar_usuario
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.post("/registrar")
async def rourtes_crear_usuario(usuario: UsuarioCrear):
    return services_crear_usuario(usuario.nombre, usuario.correo, usuario.contraseña)


@router.get("/obtener/{correo}")
async def routes_leer_usuario(correo: str):
    return services_leer_usuario(correo)


@router.post("/login")
async def routes_incio_de_sesion(credenciales: UsuarioLogin):
    return services_inicio_de_sesion(credenciales.correo, credenciales.contraseña)


@router.delete("/eliminar")
async def routes_eliminar_usuario(datos: UsuarioEliminar):
    return services_eliminar_usuario(datos.correo)





