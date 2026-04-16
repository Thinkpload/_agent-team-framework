#!/usr/bin/env bash
# Optional: expose the terminal via ngrok (public HTTPS URL, free tier).
# Requires: ngrok installed and authenticated (ngrok config add-authtoken <token>).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.env"
fi
PORT="${RT_PORT:-7681}"

if ! command -v ngrok &>/dev/null; then
    echo "ERROR: ngrok not installed." >&2
    echo "Install: https://ngrok.com/download" >&2
    exit 1
fi

echo "Starting ngrok tunnel for port $PORT..."
ngrok http "$PORT"
