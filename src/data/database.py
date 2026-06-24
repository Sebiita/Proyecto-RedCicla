import firebase_admin
from firebase_admin import credentials, firestore
import os

# ========== INICIALIZACIÓN FIREBASE ==========
# Obtener la ruta del archivo de credenciales
SERVICE_ACCOUNT_KEY_PATH = os.path.join(
    os.path.dirname(__file__), 
    "..", 
    "serviceAccountKey.json"
)

# Inicializar Firebase Admin SDK
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)

# Obtener la instancia de Firestore usando el método de Firebase Admin
db = firestore.client()

# ========== COLECCIONES ==========
# Referencia a las colecciones principales
usuarios_ref = db.collection("usuarios")
camiones_ref = db.collection("camiones")
puntos_ref = db.collection("puntos")
rutas_ref = db.collection("rutas")
fichas_ref = db.collection("fichas_realizadas")
