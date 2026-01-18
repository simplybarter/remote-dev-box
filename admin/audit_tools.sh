#!/bin/bash

# Tooling Audit Script for Remote Dev Box
# This script checks for the presence and basic functionality of all installed tools.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "    Remote Dev Box Tooling Audit"
echo "=========================================="

# -----------------------------------------------------------------------------
# Host Detection & Self-Propagation
# -----------------------------------------------------------------------------
# If we are NOT in a container (missing /.dockerenv), assume we're on the host.
if [ ! -f "/.dockerenv" ]; then
    echo "Running on Host. Detecting active dev containers..."
    
    # Find containers starting with "dev-"
    containers=$(docker ps --format "{{.Names}}" | grep "^dev-")
    
    if [ -z "$containers" ]; then
        echo "No active dev containers found."
        exit 0
    fi
    
    for container in $containers; do
        echo ""
        echo ">>> Auditing Container: $container"
        # Pipe this script into the container to run it
        cat "$0" | docker exec -i "$container" bash
    done
    
    exit 0
fi

# -----------------------------------------------------------------------------
# In-Container Audit Logic
# -----------------------------------------------------------------------------

check_tool() {
    local name=$1
    local cmd=$2
    local version_arg=${3:---version}

    if command -v "$cmd" >/dev/null 2>&1; then
        # Special case for GUI tools or sandbox-restricted apps
        local extra_flags=""
        if [ "$cmd" == "antigravity" ]; then
            extra_flags="--no-sandbox --user-data-dir=/tmp/audit-$$"
        fi
        
        if "$cmd" $extra_flags "$version_arg" >/dev/null 2>&1 || [ "$version_arg" == "skip_check" ]; then
            printf "${GREEN}[PASS]${NC} %-20s (Found: %s)\n" "$name" "$cmd"
        else
            # For XFCE/GUI tools, 'which' is often enough if they fail without DISPLAY
            case "$cmd" in
                xfwm4|xfce4-panel|xfdesktop|xfce4-terminal|antigravity)
                    printf "${GREEN}[PASS]${NC} %-20s (Found: %s, exists)\n" "$name" "$cmd"
                    ;;
                *)
                    printf "${YELLOW}[WARN]${NC} %-20s (Found but failed execution: %s)\n" "$name" "$cmd"
                    ;;
            esac
        fi
    else
        printf "${RED}[FAIL]${NC} %-20s (NOT FOUND)\n" "$name"
    fi
}

echo -e "\n--- Core System & Shell ---"
check_tool "Zsh" "zsh"
check_tool "Tmux" "tmux" "-V"
check_tool "Git" "git"
check_tool "Curl" "curl"
check_tool "Wget" "wget" "--help"
check_tool "Sudo" "sudo" "-V"
check_tool "Lsof" "lsof" "-v"

echo -e "\n--- Editors & Utils ---"
check_tool "Vim" "vim" "--version"
check_tool "Nano" "nano" "--version"
check_tool "HTop" "htop" "--version"
check_tool "JQ" "jq" "--version"
check_tool "Ripgrep" "rg" "--version"
check_tool "FZF" "fzf" "--version"
check_tool "Tree" "tree" "--version"

echo -e "\n--- XFCE & UI ---"
check_tool "Xfwm4" "xfwm4" "--version"
check_tool "Xfce Panel" "xfce4-panel" "--version"
check_tool "Xfce Desktop" "xfdesktop" "--version"
check_tool "Xfce Terminal" "xfce4-terminal" "--version"
check_tool "Screenshooter" "xfce4-screenshooter" "-h"
check_tool "Thunar (File Mgr)" "thunar" "--version"

echo -e "\n--- Languages & Dev Tools ---"
check_tool "Node.js" "node" "-v"
check_tool "NPM" "npm" "-v"
check_tool "PNPM" "pnpm" "-v"
check_tool "Python3" "python3" "--version"
check_tool "Pip" "pip" "--version"
check_tool "Pipx" "pipx" "--version"
check_tool "UV" "uv" "--version"

echo -e "\n--- AI CLI Tools ---"
check_tool "Gemini CLI" "gemini" "--version"
check_tool "Codex" "codex" "--version"
check_tool "OpenCode AI" "opencode" "--version"
check_tool "Copilot CLI" "copilot" "--version"

echo -e "\n--- Databases ---"
check_tool "SQLite3" "sqlite3" "--version"
check_tool "Postgres Client" "psql" "--version"
check_tool "Redis Tools" "redis-cli" "--version"

echo -e "\n--- Remote Access ---"
check_tool "XRDP" "xrdp" "-v"
check_tool "TigerVNC" "vncserver" "-version"

echo -e "\n--- Custom Tooling ---"
check_tool "Antigravity" "antigravity" "--version"
check_tool "Cursor" "cursor" "--version"
check_tool "Google Chrome" "google-chrome" "--version"

echo -e "\nAudit Complete."
rm -rf /tmp/audit-*
