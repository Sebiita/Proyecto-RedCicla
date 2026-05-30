from fastapi import FastAPI
from routes.usuarios_routes import router as usuarios_router

app = FastAPI()

# ========== RUTAS ==========
app.include_router(usuarios_router)

@app.get("/")
def root():
    return {"mensaje": "Servidor FastAPI funcionando"}







# Comandos útiles:
# Iniciar servidor: python -m uvicorn app:app --reload
# Iniciar servidor LAN público:
#     python -m uvicorn app:app --host 0.0.0.0 --port 8000
# Abrir chatbot:
#     http://127.0.0.1:8000/static/chat_bot/chat_bot.html
# Migrar datos: python scripts\migracion_sqlite.py
# Consulta directa:
#     python scripts\consultas_sqlite.py --query
#     "SELECT * FROM usuarios WHERE ciudad IS NOT NULL"
# Para activar el entrono virtual: source .venv/bin/activate

# pruebas unitarias
# todos los tets: pytest ../tests/ -v
# para ver los print durante la ejecucion: pytest ../tests/ -v -s
# todos los tests de routes: pytest ../tests/routes/ -v
# todos los tests de controllers: pytest ../tests/controllers/ -v
# todos los tests de services: pytest ../tests/services/ -v