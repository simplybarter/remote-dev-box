# Remote Dev Environment (Ubuntu 24.04 + XFCE + XRDP)

A fully featured, Dockerized remote development environment running Ubuntu 24.04 with an XFCE desktop, accessible via RDP.

## 🚀 Quick Start

1.  **Build and Start**:
    ```bash
    docker compose up -d --build
    ```

2.  **Connect**:
    *   Open your RDP client (Remmina, Microsoft Remote Desktop, etc.).
    *   Connect to: `localhost:3390`
    *   **User**: `testdev`
    *   **Password**: `testdev` (configurable in `.env` or `docker-compose.yml`)

3.  **Stop**:
    ```bash
    docker compose down
    ```

## 🛠️ Included Tools

### Editors & IDEs
*   **Visual Studio Code**: Pre-installed (`code`).
*   **Antigravity**: Google's AI-first IDE (`antigravity`).
*   **Cursor**: AI Code Editor (CLI Agent: `agent`, `cursor-agent`).
*   **Terminal Editors**: `vim`, `nano`.

### Development Stack
*   **Node.js**: Version 22.x (LTS)
*   **Python**: 3.x
*   **Shell**: `zsh` (with `oh-my-zsh` ready), `bash`.
*   **Git**: Version control.
*   **SSH**: `openssh-client`.

### Utilities
*   **Browser**: Google Chrome (`google-chrome`).
*   **File Transfer**: FileZilla (`filezilla`).
*   **Terminal Power Tools**:
    *   `tmux` (Multiplexer)
    *   `fzf` (Fuzzy Finder)
    *   `ripgrep` (Fast grep)
    *   `jq` (JSON processor)
    *   `htop` (Process viewer)
    *   `tree` (Directory viewer)
*   **Databases (Clients)**: `sqlite3`, `psql` (PostgreSQL), `redis-cli`.
*   **Network**: `ping`, `dig`, `curl`, `wget`.

## ⚙️ Configuration Details

*   **XRDP Backend**: Uses `Xvnc` (TigerVNC) instead of Xorg for better stability in Docker.
*   **Sandboxing**: GUI apps (Chrome, VS Code, Antigravity) are wrapped with `--no-sandbox --disable-dev-shm-usage` to prevent crashes in the containerized environment.
*   **Persistence**: The home directory `/home/testdev` is persisted via a Docker volume (`testdev_home`).

## 🐞 Troubleshooting

*   **Black Screen on Connect**:
    *   Wait a few seconds for XFCE to load.
    *   Ensure you are using the `Xvnc` backend (configured in `xrdp.ini`).

*   **GUI Apps Crashing**:
    *   Ensure you are running them via their wrappers (e.g., just type `google-chrome` or `code`). Direct binary execution might fail without the `--no-sandbox` flag.

*   **"Connection Refused" during build**:
    *   Some download URLs might block automated requests. The Dockerfile uses alternative installation methods (CLI) or user-agent spoofing where possible.
