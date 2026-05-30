from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class UsuarioBase(BaseModel):
    """Modelo base para usuario con validaciones"""
    nombre: str = Field(..., min_length=2, max_length=100, description="Nombre del usuario")
    correo: EmailStr = Field(..., description="Correo electrónico del usuario")


class UsuarioCrear(UsuarioBase):
    """Modelo para crear usuario - requiere contraseña"""
    contraseña: str = Field(..., min_length=6, max_length=100, description="Contraseña del usuario")


class UsuarioRespuesta(UsuarioBase):
    """Modelo de respuesta - sin contraseña"""
    pass


class UsuarioLogin(BaseModel):
    """Modelo para login"""
    correo: EmailStr = Field(..., description="Correo del usuario")
    contraseña: str = Field(..., description="Contraseña del usuario")


class UsuarioEliminar(BaseModel):
    """Modelo para eliminar usuario"""
    correo: EmailStr = Field(..., description="Correo del usuario a eliminar")
