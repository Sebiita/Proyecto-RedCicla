from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class UsuarioBase(BaseModel):
    """Modelo base para usuario con validaciones"""
    nombre: str = Field(..., min_length=2, max_length=100, description="Nombre del usuario")
    apellido: str = Field(..., min_length=2, max_length=100, description="Apellido del usuario")
    correo: EmailStr = Field(..., description="Correo electrónico del usuario")
    rol: str = Field(..., description="Rol del usuario (Admin, Chofer, Ayudante, etc)")
    estado: str = Field(default="Activo", description="Estado del usuario (Activo, Inactivo)")


class UsuarioCrear(UsuarioBase):
    """Modelo para crear usuario - requiere contraseña"""
    contraseña: str = Field(..., min_length=6, max_length=100, description="Contraseña del usuario")


class UsuarioActualizar(BaseModel):
    """Modelo para actualizar usuario"""
    nombre: Optional[str] = Field(None, min_length=2, max_length=100)
    apellido: Optional[str] = Field(None, min_length=2, max_length=100)
    rol: Optional[str] = None
    estado: Optional[str] = None


class UsuarioRespuesta(UsuarioBase):
    """Modelo de respuesta - sin contraseña"""
    id: Optional[int] = None


class UsuarioLogin(BaseModel):
    """Modelo para login"""
    correo: EmailStr = Field(..., description="Correo del usuario")
    contraseña: str = Field(..., description="Contraseña del usuario")


class UsuarioEliminar(BaseModel):
    """Modelo para eliminar usuario"""
    correo: EmailStr = Field(..., description="Correo del usuario a eliminar")
