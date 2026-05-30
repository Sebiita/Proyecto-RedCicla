from fastapi import APIRouter, HTTPException, status
from models.usuario import UsuarioCrear, UsuarioRespuesta, UsuarioLogin, UsuarioEliminar
from services.services_usuario import (
    services_crear_usuario,
    services_leer_usuario,
    services_inicio_de_sesion,
    services_eliminar_usuario
)

router = APIRouter(
    prefix="/usuarios",
    tags=["usuarios"],
    responses={404: {"description": "No encontrado"}}
)


@router.post("/registrar", response_model=dict, status_code=status.HTTP_201_CREATED)
async def registrar_usuario(usuario: UsuarioCrear):
    """
    Registra un nuevo usuario
    
    - **nombre**: Nombre del usuario (2-100 caracteres)
    - **correo**: Email válido del usuario
    - **contraseña**: Contraseña del usuario (mínimo 6 caracteres)
    """
    resultado = services_crear_usuario(
        nombre=usuario.nombre,
        correo=usuario.correo,
        contraseña=usuario.contraseña
    )
    
    if "error" in resultado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=resultado["error"]
        )
    
    return resultado


@router.get("/obtener/{correo}", response_model=dict)
async def obtener_usuario(correo: str):
    """
    Obtiene información de un usuario por correo
    
    - **correo**: Email del usuario a buscar
    """
    resultado = services_leer_usuario(correo=correo)
    
    if "error" in resultado:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=resultado["error"]
        )
    
    return resultado


@router.post("/login", response_model=dict)
async def login(credenciales: UsuarioLogin):
    """
    Inicia sesión con correo y contraseña
    
    - **correo**: Email del usuario
    - **contraseña**: Contraseña del usuario
    """
    resultado = services_inicio_de_sesion(
        correo=credenciales.correo,
        contraseña=credenciales.contraseña
    )
    
    if "error" in resultado:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=resultado["error"]
        )
    
    return resultado


@router.delete("/eliminar", response_model=dict)
async def eliminar_usuario(datos: UsuarioEliminar):
    """
    Elimina un usuario por correo
    
    - **correo**: Email del usuario a eliminar
    """
    resultado = services_eliminar_usuario(correo=datos.correo)
    
    if "error" in resultado:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=resultado["error"]
        )
    
    return resultado
