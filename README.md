# AI first Agentic Remote Development Environment

A Dockerized AI first Agentic Remote Development Environment running Ubuntu 24.04 with an XFCE desktop, accessible via RDP.


## ⚠️ Important Warnings

> [!CAUTION]
> **Container Lifecycle**: Running `./admin/deploy_update.sh` **DESTROYS and RECREATES** all user containers.
> *   **System Changes Lost**: Any packages installed via `apt` or system files modified *inside* the container will be **LOST**.
> *   **Persist Changes**: To make system changes permanent (e.g., installing a new library), you **MUST** add them to your `dockerfile`.
> *   **Why this matters**: This "Immutable Infrastructure" approach ensures that if a user breaks their OS, a simple rebuild fixes it. It guarantees that every developer has the exact same, working environment, eliminating "it works on my machine" issues.

> [!IMPORTANT]
> **Data Persistence**:
> *   Your home directory (`/home/<username>`) is mounted as a Docker volume.
> *   Files stored here (code, configs, downloads) **WILL PERSIST** across updates and restarts.
> *   ALWAYS store your work in your home directory.
> *   **Why this matters**: This separation means you can upgrade the OS, switch tools, or fix broken system files without ever touching or risking your actual code and project data.

> [!NOTE]
> **Password Management**:
> *   Passwords are managed via `admin/users.conf`.
> *   To change a password, use the command: `./admin/manage_users.sh update_password <user> <new_pass>`.
> *   This operation **requires a container restart**, which will verify that the new password works.
> *   **Why this matters**: Centralized password management prevents drift between the container's internal state and your deployment verification. It ensures you always know how to access your boxes.

> [!WARNING]
> **Network Security**:
> *   This environment is designed for **private network use**.
> *   If hosting on a public IP, you **MUST** use a **VPN** (e.g., WireGuard, OpenVPN) to access it.
> *   Do **NOT** expose the RDP ports (3400+) directly to the internet.
> *   **Why this matters**: RDP is a high-value target for automated botnets. Even with strong passwords, exposing these ports invites thousands of login attempts per hour, slowing down your server and risking a security breach.

## 🚀 Quick Start

1.  **Fork and Clone the repository**:

    ```bash
    # Using GitHub CLI (Recommended)
    gh repo fork simplybarter/remote-dev-box --clone

    # Or using standard Git
    git clone https://github.com/simplybarter/remote-dev-box.git
    
    cd remote-dev-box
    ```


2.  **Build the Image**:
    Run the update script. It will automatically create a local `dockerfile` from `dockerfile.example` if one doesn't exist, and then build it.
    ```bash
    ./admin/deploy_update.sh
    ```
    > **Note**: Your local `dockerfile` is `.gitignore`'d. You can customize it without fear of it being overwritten by future git pulls.


3.  **Create a User**:
    Use the admin script to create your first user. It will assign a dedicated port and persistent home volume.
    ```bash
    ./admin/manage_users.sh add myuser
    # Output: User 'myuser' created! Connect via localhost:3400
    ```

4.  **Connect**:
    *   Open your RDP client (Remmina, Microsoft Remote Desktop, etc.).
    *   Connect to: `localhost:3400` (or whatever specific port was assigned)
    *   **User**: `myuser`
    *   **Password**: `myuser` (default, or whatever you passed to the script)

5.  **Manage**:
    *   **List Users**: `./admin/manage_users.sh list`
    *   **Update All**: `./admin/deploy_update.sh`


## 🛠️ Included Tools

### Editors & IDEs
*   **Visual Studio Code**: Pre-installed (`code`).
*   **Antigravity**: Google's AI-first IDE (`antigravity`).
*   **Gemini CLI**: Official AI command line tool (`@google/gemini-cli@latest`).
*   **Codex CLI**: OpenAI's coding agent (`@openai/codex@latest`).
*   **OpenCode AI**: Advanced coding assistant (`opencode-ai@latest`).
*   **GitHub Copilot CLI**: CLI for GitHub Copilot (`gh copilot` / `github-copilot-cli`).
*   **Claude Code**: Anthropic's AI coding agent (`claude`).
*   **Cursor**: AI Code Editor (`cursor`).
*   **Terminal Editors**: `vim`, `nano`.

### Development Stack
*   **Node.js**: Version 22.x (LTS) with `npm`, `pnpm`
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
All scripts support the `-h` or `--help` flag to display usage instructions.

1.  **`./admin/manage_users.sh`**:
    *   `add <username> [password]`: Creates a new container for a user over a unique port.
    *   `remove <username>`: Destroys the container (keeps data volume safe).
    *   `list`: Shows all active users and their ports.
    *   `backup <username>`: Creates a `.tar.gz` backup of the user's home directory.
    *   `update_password <username> <new_password>`: Updates the user's password and restarts their container.

4.  **`./admin/monitor.sh`**:
    *   Shows a dashboard of current CPU/RAM usage per user.
    *   Lists the disk space consumed by each user's volume.

2.  **`./admin/deploy_update.sh`**:
    *   `./admin/deploy_update.sh`: Builds using the default `dockerfile`.
    *   `./admin/deploy_update.sh --default`: Resets `dockerfile` from `dockerfile.example` before building.
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
*   **Sandboxing**: The container runs with `--security-opt seccomp=unconfined` to allow Electron apps (Chrome, VS Code) to use their native sandboxing mechanisms.
*   **Persistence**: The home directory `/home/testdev` is persisted via a Docker volume (`testdev_home`).

## 🐞 Troubleshooting

*   **Black Screen on Connect**:
    *   Wait a few seconds for XFCE to load.
    *   Ensure you are using the `Xvnc` backend (configured in `xrdp.ini`).

*   **GUI Apps Crashing**:
    *   Previously, wrappers were needed (`--no-sandbox`). Now, `seccomp=unconfined` handles this native support.
    *   If issues persist, check `admin/deploy_update.sh` to ensure the security option is being passed to `docker run`.

*   **"Connection Refused" during build**:
    *   Some download URLs might block automated requests. The Dockerfile uses alternative installation methods (CLI) or user-agent spoofing where possible.
