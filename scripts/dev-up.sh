#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
RUN_DIR="$ROOT_DIR/.run"
LOG_DIR="$RUN_DIR/logs"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"

mkdir -p "$LOG_DIR"

is_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

cleanup_stale_pid_file() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"
    if ! is_running "$pid"; then
      rm -f "$pid_file"
    fi
  fi
}

cleanup_stale_pid_file "$BACKEND_PID_FILE"
cleanup_stale_pid_file "$FRONTEND_PID_FILE"

port_in_use() {
  local port="$1"
  lsof -i ":$port" -sTCP:LISTEN -n -P >/dev/null 2>&1
}

if [[ -f "$BACKEND_PID_FILE" ]]; then
  echo "Backend already running with PID $(cat "$BACKEND_PID_FILE")."
  echo "Run ./scripts/dev-down.sh first if you want a clean restart."
  exit 1
fi

if [[ -f "$FRONTEND_PID_FILE" ]]; then
  echo "Frontend already running with PID $(cat "$FRONTEND_PID_FILE")."
  echo "Run ./scripts/dev-down.sh first if you want a clean restart."
  exit 1
fi

if port_in_use 5000; then
  echo "Port 5000 is already in use. Stop that process and rerun ./scripts/dev-up.sh."
  exit 1
fi

if port_in_use 5173; then
  echo "Port 5173 is already in use. Stop that process and rerun ./scripts/dev-up.sh."
  exit 1
fi

if [[ ! -d "$BACKEND_DIR/.venv" ]]; then
  echo "Creating backend virtual environment..."
  (
    cd "$BACKEND_DIR"
    python3 -m venv .venv
  )
fi

if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
  echo "Installing frontend dependencies..."
  (
    cd "$FRONTEND_DIR"
    npm install
  )
fi

echo "Starting backend..."
(
  cd "$BACKEND_DIR"
  source .venv/bin/activate
  pip install -r requirements.txt >/dev/null
  python -c 'from app import app; app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)' >"$LOG_DIR/backend.log" 2>&1
) &
echo $! >"$BACKEND_PID_FILE"

echo "Starting frontend..."
(
  cd "$FRONTEND_DIR"
  npm run dev -- --host 0.0.0.0 --port 5173 --strictPort >"$LOG_DIR/frontend.log" 2>&1
) &
echo $! >"$FRONTEND_PID_FILE"

wait_for_port() {
  local port="$1"
  local timeout_seconds="$2"
  local start_time
  start_time="$(date +%s)"

  while true; do
    if port_in_use "$port"; then
      return 0
    fi

    if (( $(date +%s) - start_time >= timeout_seconds )); then
      return 1
    fi

    sleep 1
  done
}

if ! wait_for_port 5000 30; then
  echo "Backend did not start on port 5000 within 30 seconds."
  echo "---- backend.log ----"
  tail -n 40 "$LOG_DIR/backend.log" || true
  "$ROOT_DIR/scripts/dev-down.sh" >/dev/null 2>&1 || true
  exit 1
fi

if ! wait_for_port 5173 30; then
  echo "Frontend did not start on port 5173 within 30 seconds."
  echo "---- frontend.log ----"
  tail -n 40 "$LOG_DIR/frontend.log" || true
  "$ROOT_DIR/scripts/dev-down.sh" >/dev/null 2>&1 || true
  exit 1
fi

echo ""
echo "Services started:"
echo "- Backend:  http://127.0.0.1:5000"
echo "- Frontend: http://localhost:5173"
echo ""
echo "Logs:"
echo "- $LOG_DIR/backend.log"
echo "- $LOG_DIR/frontend.log"
echo ""
echo "To stop everything, run: ./scripts/dev-down.sh"
