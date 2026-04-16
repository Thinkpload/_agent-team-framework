#!/usr/bin/env bash
# Stop the ttyd web terminal server (keeps the tmux session alive).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PID_FILE="$SCRIPT_DIR/ttyd.pid"

if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Stopped ttyd (PID $PID)"
    else
        echo "ttyd was not running (stale PID file)"
    fi
    rm -f "$PID_FILE"
else
    # Fallback: kill by process name
    if pkill -f "ttyd" 2>/dev/null; then
        echo "Stopped ttyd"
    else
        echo "ttyd was not running"
    fi
fi

echo ""
echo "tmux session is still alive. To kill it too:"

# Load session name from config if available
if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.env"
fi
SESSION="${RT_SESSION:-claude-remote}"
echo "  tmux kill-session -t $SESSION"
