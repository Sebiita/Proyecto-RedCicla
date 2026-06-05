from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes.routes_usuarios import router as usuarios_router
from routes.routes_camion import router as camion_router
from routes.routes_punto import router as punto_router
from routes.routes_ruta import router as ruta_router

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

app.mount("/static", StaticFiles(directory="static"), name="static")

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


