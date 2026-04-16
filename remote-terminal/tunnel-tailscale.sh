#!/usr/bin/env bash
# Optional: expose the terminal via Tailscale Funnel (public HTTPS URL).
# Requires: tailscale installed and authenticated.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.env"
fi
PORT="${RT_PORT:-7681}"

if ! command -v tailscale &>/dev/null; then
    echo "ERROR: tailscale not installed." >&2
    echo "Install: https://tailscale.com/download/linux" >&2
    exit 1
fi

echo "Starting Tailscale Funnel for port $PORT..."
echo "(This creates a public HTTPS URL accessible from anywhere)"
echo ""

# Funnel exposes the local port publicly via Tailscale
tailscale funnel "$PORT"
