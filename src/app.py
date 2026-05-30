from fastapi import FastAPI
from routes.routes_usuarios import router as usuarios_router
from routes.routes_camion import router as camion_router
from routes.routes_punto import router as punto_router
from routes.routes_ruta import router as ruta_router

app = FastAPI()

# ========== RUTAS ==========
app.include_router(usuarios_router)
app.include_router(camion_router)
app.include_router(punto_router)
app.include_router(ruta_router)

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


