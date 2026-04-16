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
RT_BIND_TAILSCALE="${RT_BIND_TAILSCALE:-1}"

# Expand tilde in workdir
RT_WORKDIR="${RT_WORKDIR/#\~/$HOME}"

# ── Resolve bind address ──────────────────────────────────────────────────────
BIND_ADDR="0.0.0.0"
TS_IP=""
TS_HOST=""

if [[ "$RT_BIND_TAILSCALE" == "1" ]]; then
    if ! command -v tailscale &>/dev/null; then
        echo "ERROR: tailscale not found but RT_BIND_TAILSCALE=1." >&2
        echo "Install Tailscale or set RT_BIND_TAILSCALE=0 in config.env." >&2
        exit 1
    fi
    if ! tailscale status &>/dev/null; then
        echo "ERROR: Tailscale is not connected. Run: sudo tailscale up" >&2
        exit 1
    fi
    TS_IP="$(tailscale ip -4 2>/dev/null | head -1)"
    if [[ -z "$TS_IP" ]]; then
        echo "ERROR: Could not get Tailscale IP. Is Tailscale running?" >&2
        exit 1
    fi
    # MagicDNS hostname (strip trailing dot if present)
    TS_HOST="$(tailscale status --json 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'].rstrip('.'))" \
        2>/dev/null || echo "")"
    BIND_ADDR="$TS_IP"
    echo "✓ Tailscale IP: $TS_IP${TS_HOST:+  MagicDNS: $TS_HOST}"
fi

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
    --interface "$BIND_ADDR"
    --terminal-type xterm-256color
)

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
echo ""
echo "════════════════════════════════════════════════"
echo " Claude Code Remote Terminal is running!"
echo "════════════════════════════════════════════════"
echo ""
if [[ -n "$TS_IP" ]]; then
    echo " Tailscale (from Android — open in Chrome):"
    echo "   http://${TS_IP}:${RT_PORT}"
    if [[ -n "$TS_HOST" ]]; then
        echo "   http://${TS_HOST}:${RT_PORT}   (MagicDNS)"
    fi
    echo ""
    echo "   Traffic is encrypted by WireGuard — no TLS needed."
else
    LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_PC_IP")"
    echo " Local network:"
    echo "   http://${LOCAL_IP}:${RT_PORT}"
fi
echo ""
echo " Login:"
echo "   User: ${RT_USER}"
echo "   Pass: ${RT_PASS}"
echo ""
echo " tmux session: $RT_SESSION"
echo " ttyd PID: $TTYD_PID  (log: $SCRIPT_DIR/ttyd.log)"
echo ""
echo " To stop: ./stop-server.sh"
echo "════════════════════════════════════════════════"
