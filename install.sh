#!/usr/bin/env bash
# install.sh — install claudeep to your PATH
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

CLI_NAME="claudeep"
SETUP_URL="https://raw.githubusercontent.com/xuechaow/claudeep/main/setup.sh"

# ── Pick install directory ────────────────────────────────────────────
if [[ -d /usr/local/bin ]] && [[ -w /usr/local/bin ]]; then
    BIN_DIR="/usr/local/bin"
elif [[ -d "$HOME/.local/bin" ]]; then
    BIN_DIR="$HOME/.local/bin"
elif [[ -d "$HOME/bin" ]]; then
    BIN_DIR="$HOME/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

TARGET="${BIN_DIR}/${CLI_NAME}"

echo ""
echo -e "${BOLD}claudeep — Claude Code + DeepSeek${NC}"
echo ""

# ── Download ──────────────────────────────────────────────────────────
echo -e "  Installing to ${GREEN}${TARGET}${NC} ..."
curl -fsSL "$SETUP_URL" -o "$TARGET" || {
    echo -e "  ${RED}Failed to download.${NC}"
    exit 1
}
chmod +x "$TARGET"

# ── Check PATH ────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -qF "$BIN_DIR"; then
    echo ""
    echo -e "  ${YELLOW}${BIN_DIR} is not in your PATH.${NC}"
    echo ""
    SHELL_RC=""
    case "$(basename "${SHELL:-/bin/bash}")" in
        zsh)  SHELL_RC="${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash) SHELL_RC="$HOME/.bashrc" ;;
        fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
    esac
    if [[ -n "$SHELL_RC" ]]; then
        echo "  Add this line to ${SHELL_RC}:"
        echo ""
        echo -e "    ${BOLD}export PATH=\"${BIN_DIR}:\$PATH\"${NC}"
        echo ""
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────
echo -e "  ${GREEN}Installed.${NC} Run:"
echo ""
echo -e "    ${BOLD}${CLI_NAME}${NC}"
echo ""

# Offer to run setup immediately (read from tty so pipe doesn't steal input)
if [[ -t 0 ]] || [[ -e /dev/tty ]]; then
    echo -n "  Set up now? [Y/n] "
    read -r reply < /dev/tty
    if [[ -z "$reply" ]] || [[ "$reply" =~ ^[Yy] ]]; then
        echo ""
        exec "$TARGET" < /dev/tty
    fi
fi
