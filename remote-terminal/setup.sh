#!/usr/bin/env bash
# One-time setup: installs ttyd, tmux, and optional tunnel tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Remote Terminal Setup ==="

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
PKG_MANAGER=""

if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
elif command -v brew &>/dev/null; then
    PKG_MANAGER="brew"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
else
    echo "ERROR: Unsupported package manager. Install ttyd and tmux manually." >&2
    exit 1
fi

# ── Install tmux ──────────────────────────────────────────────────────────────
if ! command -v tmux &>/dev/null; then
    echo "Installing tmux..."
    case "$PKG_MANAGER" in
        apt)    sudo apt-get install -y tmux ;;
        brew)   brew install tmux ;;
        pacman) sudo pacman -S --noconfirm tmux ;;
        dnf)    sudo dnf install -y tmux ;;
    esac
else
    echo "✓ tmux already installed ($(tmux -V))"
fi

# ── Install ttyd ──────────────────────────────────────────────────────────────
if ! command -v ttyd &>/dev/null; then
    echo "Installing ttyd..."
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get install -y ttyd 2>/dev/null || _install_ttyd_binary
            ;;
        brew)
            brew install ttyd
            ;;
        pacman)
            sudo pacman -S --noconfirm ttyd 2>/dev/null || _install_ttyd_binary
            ;;
        dnf)
            sudo dnf install -y ttyd 2>/dev/null || _install_ttyd_binary
            ;;
    esac
else
    echo "✓ ttyd already installed"
fi

_install_ttyd_binary() {
    echo "Downloading ttyd binary..."
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  TTYD_ARCH="x86_64" ;;
        aarch64) TTYD_ARCH="aarch64" ;;
        armv7l)  TTYD_ARCH="arm" ;;
        *)       echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
    esac
    TTYD_URL="https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.${TTYD_ARCH}"
    sudo curl -L "$TTYD_URL" -o /usr/local/bin/ttyd
    sudo chmod +x /usr/local/bin/ttyd
}

# ── Check claude CLI ──────────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
    echo "✓ Claude Code CLI found: $(which claude)"
else
    echo "⚠ Claude Code CLI not found in PATH."
    echo "  Install it: npm install -g @anthropic-ai/claude-code"
fi

# ── Create config.env from example if missing ─────────────────────────────────
if [[ ! -f "$SCRIPT_DIR/config.env" ]]; then
    cp "$SCRIPT_DIR/config.env.example" "$SCRIPT_DIR/config.env"
    echo ""
    echo "Created config.env — edit it before starting:"
    echo "  nano $SCRIPT_DIR/config.env"
else
    echo "✓ config.env already exists"
fi

echo ""
echo "=== Setup complete ==="
echo "Next: edit config.env, then run ./start-server.sh"
