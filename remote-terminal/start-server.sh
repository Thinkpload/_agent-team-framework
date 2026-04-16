#!/usr/bin/env bash
# Start Claude Code in a tmux session and expose it via ttyd web terminal.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load config ───────────────────────────────────────────────────────────────
if [[ ! -f "$SCRIPT_DIR/config.env" ]]; then
    echo "ERROR: config.env not found. Run ./setup.sh first." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.env"

RT_PORT="${RT_PORT:-7681}"
RT_USER="${RT_USER:-admin}"
RT_PASS="${RT_PASS:-changeme123}"
RT_SESSION="${RT_SESSION:-claude-remote}"
RT_WORKDIR="${RT_WORKDIR:-$HOME}"
RT_TLS="${RT_TLS:-0}"

# Expand tilde in workdir
RT_WORKDIR="${RT_WORKDIR/#\~/$HOME}"

# ── Dependency check ──────────────────────────────────────────────────────────
for cmd in tmux ttyd; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' not found. Run ./setup.sh first." >&2
        exit 1
    fi
done

# ── tmux session ──────────────────────────────────────────────────────────────
if tmux has-session -t "$RT_SESSION" 2>/dev/null; then
    echo "tmux session '$RT_SESSION' already running."
else
    echo "Starting tmux session '$RT_SESSION'..."
    mkdir -p "$RT_WORKDIR"
    tmux new-session -d -s "$RT_SESSION" -c "$RT_WORKDIR"

    # Show welcome banner, then launch Claude Code
    tmux send-keys -t "$RT_SESSION" \
        "echo '=== Claude Code Remote Terminal ===' && cd \"$RT_WORKDIR\" && claude" \
        Enter
    echo "✓ tmux session started"
fi

# ── ttyd server ───────────────────────────────────────────────────────────────
# Kill any existing ttyd on this port
if pgrep -f "ttyd.*$RT_PORT" &>/dev/null; then
    echo "Stopping existing ttyd on port $RT_PORT..."
    pkill -f "ttyd.*$RT_PORT" || true
    sleep 1
fi

TTYD_ARGS=(
    --port "$RT_PORT"
    --credential "${RT_USER}:${RT_PASS}"
    --writable
    --once=false
    --interface 0.0.0.0
)

# Mobile-friendly font and xterm settings
TTYD_ARGS+=(--terminal-type xterm-256color)
TTYD_ARGS+=(--index /dev/null)   # use built-in xterm.js UI

# TLS (self-signed) for external HTTPS access
if [[ "$RT_TLS" == "1" ]]; then
    CERT_DIR="$SCRIPT_DIR/.certs"
    mkdir -p "$CERT_DIR"
    if [[ ! -f "$CERT_DIR/server.crt" ]]; then
        echo "Generating self-signed TLS certificate..."
        openssl req -x509 -nodes -newkey rsa:2048 \
            -keyout "$CERT_DIR/server.key" \
            -out "$CERT_DIR/server.crt" \
            -days 3650 \
            -subj "/CN=claude-remote" 2>/dev/null
    fi
    TTYD_ARGS+=(--ssl --ssl-cert "$CERT_DIR/server.crt" --ssl-key "$CERT_DIR/server.key")
fi

TTYD_CMD=(tmux attach-session -t "$RT_SESSION")

echo "Starting ttyd on port $RT_PORT..."
nohup ttyd "${TTYD_ARGS[@]}" "${TTYD_CMD[@]}" \
    > "$SCRIPT_DIR/ttyd.log" 2>&1 &
TTYD_PID=$!
echo "$TTYD_PID" > "$SCRIPT_DIR/ttyd.pid"

sleep 1
if ! kill -0 "$TTYD_PID" 2>/dev/null; then
    echo "ERROR: ttyd failed to start. Check $SCRIPT_DIR/ttyd.log" >&2
    cat "$SCRIPT_DIR/ttyd.log"
    exit 1
fi

# ── Print access info ─────────────────────────────────────────────────────────
PROTO="http"
[[ "$RT_TLS" == "1" ]] && PROTO="https"

LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_PC_IP")"

echo ""
echo "════════════════════════════════════════════════"
echo " Claude Code Remote Terminal is running!"
echo "════════════════════════════════════════════════"
echo ""
echo " Local network (same WiFi):"
echo "   ${PROTO}://${LOCAL_IP}:${RT_PORT}"
echo ""
echo " Login:"
echo "   User: ${RT_USER}"
echo "   Pass: ${RT_PASS}"
echo ""
if [[ -n "${RT_PUBLIC_URL:-}" ]]; then
    echo " Public URL (Tailscale/ngrok):"
    echo "   ${RT_PUBLIC_URL}"
    echo ""
fi
echo " tmux session: $RT_SESSION"
echo " ttyd PID: $TTYD_PID  (log: $SCRIPT_DIR/ttyd.log)"
echo ""
echo " To stop: ./stop-server.sh"
echo "════════════════════════════════════════════════"
