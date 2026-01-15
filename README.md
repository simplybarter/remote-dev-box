# Remote Dev Environment (Ubuntu 24.04 + XFCE + XRDP)

A fully featured, Dockerized remote development environment running Ubuntu 24.04 with an XFCE desktop, accessible via RDP.

## 🚀 Quick Start

1.  **Build the Image**:
    The admin scripts will automatically build the image on first use, or you can build it manually:
    ```bash
    docker build -t remote-dev-image .
    ```

2.  **Create a User**:
    Use the admin script to create your first user. It will assign a dedicated port and persistent home volume.
    ```bash
    ./admin/manage_users.sh add myuser
    # Output: User 'myuser' created! Connect via localhost:3400
    ```

3.  **Connect**:
    *   Open your RDP client (Remmina, Microsoft Remote Desktop, etc.).
    *   Connect to: `localhost:3400` (or whatever specific port was assigned)
    *   **User**: `myuser`
    *   **Password**: `myuser` (default, or whatever you passed to the script)

4.  **Manage**:
    *   **List Users**: `./admin/manage_users.sh list`
    *   **Update All**: `./admin/deploy_update.sh`


## 🛠️ Included Tools

### Editors & IDEs
*   **Visual Studio Code**: Pre-installed (`code`).
*   **Antigravity**: Google's AI-first IDE (`antigravity`).
*   **Gemini CLI**: Official AI command line tool (`@google/gemini-cli@latest`).
*   **Codex CLI**: OpenAI's coding agent (`@openai/codex@latest`).
*   **GitHub Copilot CLI**: CLI for GitHub Copilot (`gh copilot` / `github-copilot-cli`).
*   **Cursor**: AI Code Editor (CLI Agent: `agent`, `cursor-agent`).
*   **Terminal Editors**: `vim`, `nano`.

### Development Stack
*   **Node.js**: Version 22.x (LTS)
*   **Python**: 3.12 (System Default) & 3.14 (Latest Stable)
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

## 👥 User Management & Admin Scripts

This project supports multi-user deployment where each user gets their own isolated container with persistent data.

### Scripts in `admin/`

1.  **`./admin/manage_users.sh`**:
    *   `add <username> [password]`: Creates a new container for a user over a unique port.
    *   `remove <username>`: Destroys the container (keeps data volume safe).
    *   `list`: Shows all active users and their ports.
    *   `backup <username>`: Creates a `.tar.gz` backup of the user's home directory.

4.  **`./admin/monitor.sh`**:
    *   Shows a dashboard of current CPU/RAM usage per user.
    *   Lists the disk space consumed by each user's volume.

2.  **`./admin/deploy_update.sh`**:
    *   `./admin/deploy_update.sh`: Builds using the default `dockerfile`.
    *   `./admin/deploy_update.sh --dockerfile <path>`: Builds using a custom Dockerfile.
    *   Updates the entire fleet.
    *   Rebuilds the Docker image.
    *   Recreates every user container (preserving data) to apply new tools/fixes.

### Example Workflow
```bash
# 1. Create a user named 'alice'
./admin/manage_users.sh add alice secret123
# (Alice connects via localhost:3401)

# 2. Add a new tool to Dockerfile (e.g., 'golang')
# ... edit Dockerfile ...

# 3. Rollout update to Alice and everyone else
./admin/deploy_update.sh
```

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
