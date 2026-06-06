from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes.routes_usuarios import router as usuarios_router
from routes.routes_camion import router as camion_router
from routes.routes_punto import router as punto_router
from routes.routes_ruta import router as ruta_router
from pathlib import Path
import os
from dotenv import load_dotenv

# ========== INICIALIZACIÓN FIREBASE ==========
# Importar para inicializar la conexión a Firestore
from data.database import db

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ========== RUTAS ==========
app.include_router(usuarios_router)
app.include_router(camion_router)
app.include_router(punto_router)
app.include_router(ruta_router)

BASE_DIR = Path(__file__).resolve().parent
# Limpiar la variable de entorno para forzar que load_dotenv() la refresque desde .env
if 'GOOGLE_MAPS_API_KEY' in os.environ:
    del os.environ['GOOGLE_MAPS_API_KEY']
load_dotenv(BASE_DIR.parent / '.env', override=True)
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', '')

app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")


@app.get("/config")
def get_config():
    # Cargar la .env en cada petición para reflejar cambios inmediatos
    try:
        # Leer directamente .env para evitar problemas de caché
        env_path = BASE_DIR.parent / '.env'
        key = ''
        if env_path.exists():
            for line in env_path.read_text(encoding='utf-8').splitlines():
                line = line.strip()
                if line.startswith('GOOGLE_MAPS_API_KEY='):
                    key = line.split('=', 1)[1].strip()
                    break

        key_valid = bool(key and key.startswith('AIza'))
        return {"google_maps_api_key": key, "google_maps_api_key_valid": key_valid}
    except Exception:
        return {"google_maps_api_key": "", "google_maps_api_key_valid": False}

@app.get("/")
def root():
    return {"mensaje": "Servidor FastAPI funcionando"}







# Comandos útiles:
# Iniciar servidor: python -m uvicorn app:app --reload
# Iniciar servidor LAN público:
# python -m uvicorn app:app --host 0.0.0.0 --port 8000
# probar endpoint : http://127.0.0.1:8000/docs
# recomendaciones: usar un etorno virtual para no instalar dependencias globalmente, por ejemplo con venv:
# python3 -m venv .venv  
# source .venv/bin/activate   # activar entorno virtual
# deactivate                   # desactivar entorno virtual
# pip install -r requirements.txt     # instalar dependencias


