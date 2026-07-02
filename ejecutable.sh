#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
VENV_DIR="$ROOT_DIR/.venv"
FLUTTER_DIR="$ROOT_DIR/red_cicla_app"
BACKEND_PORT="${BACKEND_PORT:-8000}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
FRONTEND_URL="http://${BACKEND_HOST}:${BACKEND_PORT}/static/landing.html"
EMULATOR_ID="${EMULATOR_ID:-RedCicla_Pixel}"

BACKEND_PID=""
EMULATOR_PID=""

log() {
  printf '\033[1;32m[%s]\033[0m %s\n' "RedCicla" "$*"
}

warn() {
  printf '\033[1;33m[%s]\033[0m %s\n' "RedCicla" "$*" >&2
}

error() {
  printf '\033[1;31m[%s]\033[0m %s\n' "RedCicla" "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    log "Deteniendo backend (PID $BACKEND_PID)..."
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi

  if [[ -n "$EMULATOR_PID" ]] && kill -0 "$EMULATOR_PID" 2>/dev/null; then
    warn "El emulador sigue activo (PID $EMULATOR_PID). Ciérralo manualmente si no lo necesitas."
  fi
}

trap cleanup EXIT INT TERM

setup_env() {
  export PATH="$HOME/development/flutter/bin:${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools:${ANDROID_HOME:-$HOME/Android/Sdk}/emulator:$PATH"
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
}

require_backend() {
  [[ -x "$VENV_DIR/bin/python" ]] || error "No existe .venv. Ejecuta: python3.12 -m venv .venv && .venv/bin/pip install -r src/requirements.txt"
  [[ -f "$SRC_DIR/app.py" ]] || error "No se encontró src/app.py"
}

require_flutter() {
  # Si estamos en flatpak, ignoramos la verificación estricta de comando local
  if ! [[ -f /.flatpak-info ]]; then
    command -v flutter >/dev/null 2>&1 || error "Flutter no está en PATH. Agrega ~/development/flutter/bin a tu shell."
  fi
  [[ -f "$FLUTTER_DIR/pubspec.yaml" ]] || error "No se encontró red_cicla_app/pubspec.yaml"
}

wait_for_backend() {
  local retries=30
  while (( retries > 0 )); do
    if curl -fsS "http://${BACKEND_HOST}:${BACKEND_PORT}/" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    (( retries-- ))
  done
  error "El backend no respondió en http://${BACKEND_HOST}:${BACKEND_PORT}"
}

start_backend() {
  log "Iniciando backend FastAPI en http://${BACKEND_HOST}:${BACKEND_PORT}"
  (
    cd "$SRC_DIR"
    exec "$VENV_DIR/bin/python" -m uvicorn app:app \
      --host "$BACKEND_HOST" \
      --port "$BACKEND_PORT" \
      --reload
  ) &
  BACKEND_PID=$!
  wait_for_backend
  log "Backend listo. API docs: http://${BACKEND_HOST}:${BACKEND_PORT}/docs"
}

open_frontend() {
  log "Abriendo frontend web: $FRONTEND_URL"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$FRONTEND_URL" >/dev/null 2>&1 &
  elif command -v gio >/dev/null 2>&1; then
    gio open "$FRONTEND_URL" >/dev/null 2>&1 &
  else
    warn "No se pudo abrir el navegador automáticamente. Abre manualmente: $FRONTEND_URL"
  fi
}

pick_flutter_device() {
  # Si el usuario define FLUTTER_DEVICE, lo usamos
  if [[ -n "${FLUTTER_DEVICE:-}" ]]; then
    printf '%s\n' "-d $FLUTTER_DEVICE"
  else
    # De lo contrario, no pasamos -d para que Flutter use el dispositivo USB conectado automáticamente
    printf '%s\n' ""
  fi
}
run_flutter_app() {
  log "Resolviendo dependencias Flutter..."
  (
    cd "$FLUTTER_DIR"
    if [[ -f /.flatpak-info ]]; then
      flatpak-spawn --host "$HOME/development/flutter/bin/flutter" pub get >/dev/null
    else
      flutter pub get >/dev/null
    fi
  )

  # --- INYECTAR LA KEY DIRECTAMENTE EN LOS RECURSOS DE ANDROID ---
  if [[ -f "$SRC_DIR/.env" ]]; then
    local maps_key
    maps_key=$(grep -E '^GOOGLE_MAPS_API_KEY=' "$SRC_DIR/.env" | head -n 1 | cut -d '=' -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    
    if [[ -n "$maps_key" ]]; then
      log "Inyectando GOOGLE_MAPS_API_KEY en los recursos de Android..."
      # Creamos o sobreescribimos el archivo strings.xml para que Android tenga la clave de forma nativa temporalmente
      mkdir -p "$FLUTTER_DIR/android/app/src/main/res/values"
      cat <<EOF > "$FLUTTER_DIR/android/app/src/main/res/values/strings.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="maps_api_key">$maps_key</string>
</resources>
EOF
    else
      warn "GOOGLE_MAPS_API_KEY está vacío en el archivo .env"
    fi
  else
    warn "No se encontró el archivo .env en $SRC_DIR"
  fi
  # -------------------------------------------------------------

  local device_flag
  device_flag="$(pick_flutter_device)"
  log "Ejecutando app Flutter en tu teléfono/dispositivo conectado..."

  cd "$FLUTTER_DIR"
  
  # Como ya inyectamos la clave en strings.xml, corremos el comando normal
  if [[ -f /.flatpak-info ]]; then
    exec flatpak-spawn --host --env=PATH="$PATH" "$HOME/development/flutter/bin/flutter" run $device_flag --dds-port 8010
  else
    flutter run $device_flag
  fi
}

main() {
  setup_env
  require_backend
  require_flutter

  start_backend
  open_frontend
  run_flutter_app
}

main "$@"


#flatpak-spawn --host $HOME/Android/Sdk/emulator/emulator -avd RedCicla_Pixel &

#BACKEND_PORT=8000 EMULATOR_ID=RedCicla_Pixel ./ejecutable.sh