"""
Módulo de seguridad y autenticación JWT para RedCicla.

Proporciona funciones para:
- Crear tokens de acceso JWT.
- Decodificar y validar tokens desde el header Authorization.
- Proteger endpoints con roles de usuario.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from pydantic import BaseModel
import os

# ── Configuración JWT ─────────────────────────────────────────-
ALGORITHM = "HS256"
DEFAULT_SECRET_KEY = "redcicla-dev-secret-key"
DEFAULT_EXPIRE_MINUTES = "480"


def _secret_key() -> str:
    """Lee la clave secreta desde las variables de entorno."""
    return os.getenv("SECRET_KEY", DEFAULT_SECRET_KEY)


def _expire_minutes() -> int:
    """Lee el tiempo de expiración del token desde las variables de entorno."""
    return int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", DEFAULT_EXPIRE_MINUTES)
    )


# Esquema de seguridad Bearer para Swagger UI
security_bearer = HTTPBearer(auto_error=False)


class TokenData(BaseModel):
    """Datos extraídos de un token JWT válido."""
    correo: Optional[str] = None
    rol: Optional[str] = None


def crear_token_acceso(
    correo: str,
    rol: str,
    expira_minutos: Optional[int] = None
) -> str:
    """
    Crea un token JWT de acceso con el correo y rol del usuario.

    Args:
        correo: Correo electrónico del usuario.
        rol: Rol del usuario (admin, conductor, ayudante, etc.).
        expira_minutos: Minutos hasta la expiración del token.

    Returns:
        Token JWT codificado como string.
    """
    if expira_minutos is None:
        expira_minutos = _expire_minutes()

    expiracion = datetime.now(timezone.utc) + timedelta(
        minutes=expira_minutos
    )
    payload = {
        "sub": correo,
        "rol": rol.lower(),
        "exp": expiracion,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, _secret_key(), algorithm=ALGORITHM)


def decodificar_token(token: str) -> TokenData:
    """
    Decodifica un token JWT y retorna los datos del usuario.

    Raises:
        JWTError: Si el token es inválido o expiró.
    """
    payload = jwt.decode(token, _secret_key(), algorithms=[ALGORITHM])
    correo = payload.get("sub")
    rol = payload.get("rol")

    if correo is None:
        raise JWTError("Token sin sujeto (sub)")

    return TokenData(correo=correo, rol=rol)


def _extraer_token(
    credenciales: Optional[HTTPAuthorizationCredentials]
) -> str:
    """Extrae el token del header Authorization."""
    if credenciales is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No se proporcionó token de autenticación",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return credenciales.credentials


async def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(security_bearer)
) -> TokenData:
    """
    Dependencia de FastAPI que obtiene el usuario actual desde el token JWT.

    Returns:
        TokenData con correo y rol del usuario autenticado.

    Raises:
        HTTPException 401 si el token falta, es inválido o expiró.
    """
    token = _extraer_token(credenciales)
    try:
        return decodificar_token(token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def requerir_admin(
    usuario: TokenData = Depends(obtener_usuario_actual)
) -> TokenData:
    """
    Dependencia de FastAPI que requiere que el usuario tenga rol admin.

    Raises:
        HTTPException 403 si el usuario no es administrador.
    """
    rol = (usuario.rol or "").lower()
    if rol not in ("admin", "administrador"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requiere rol de administrador",
        )
    return usuario
