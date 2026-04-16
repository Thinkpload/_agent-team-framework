#!/usr/bin/env bash
# Optional: expose via Tailscale Funnel (public HTTPS URL, no Tailscale app on client needed).
# With a tailnet you normally DON'T need this — just connect Android via Tailscale app directly.
# Use Funnel only if you want a public URL accessible without the Tailscale client.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.env"
fi
PORT="${RT_PORT:-7681}"

if ! command -v tailscale &>/dev/null; then
    echo "ERROR: tailscale not installed." >&2
    exit 1
fi

echo "Starting Tailscale Funnel for port $PORT..."
echo "Note: with a tailnet, your Android can reach the terminal directly"
echo "without Funnel — just use the Tailscale IP shown by start-server.sh."
echo ""
tailscale funnel "$PORT"
