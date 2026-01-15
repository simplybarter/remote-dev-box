# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-01-15

### Added
- **Base System**: Ubuntu 24.04 LTS (Noble Numbat) with XFCE4 Desktop and XRDP (TigerVNC backend).
    - `locales` (Generated `en_US.UTF-8`).
- **Core Languages**:
    - Python 3.12 (System) & Python 3.14 (DeadSnakes PPA).
    - Node.js 22.x (LTS) with `npm`, `pnpm` (Global).
- **Editors & IDEs**:
    - Visual Studio Code (Microsoft Official).
    - Terminal Editors: `vim`, `nano`.
- **AI Tooling**:
    - Antigravity (Google AI IDE).
    - Cursor (AI Code Editor & Agent CLI).
    - Google Gemini CLI (`@google/gemini-cli`).
    - OpenAI Codex CLI (`@openai/codex`).
    - OpenCode AI CLI (`opencode-ai`).
    - GitHub Copilot CLI (`gh copilot`).
- **Dev Utilities**:
    - `pipx` (Install and Run Python Applications).
    - `uv` (Fast Python package installer).
    - `git` (Version Control).
    - `gh` (GitHub CLI).
    - `openssh-client`.
    - `bash-completion`.
    - `tmux` (Terminal Multiplexer).
    - `ripgrep`, `jq`, `fzf`, `htop`, `tree`, `lsof`.
    - `7zip` (Archive manager).
    - `iproute2` (Modern networking tools).
- **Applications**:
    - Google Chrome (Browser).
    - FileZilla (FTP/SFTP Client).
    - DB Clients: `sqlite3`, `psql` (PostgreSQL), `redis-tools`.
- **Infrastructure**:
    - Automated user management scripts (`admin/manage_users.sh`).
    - Self-updating deployment script (`admin/deploy_update.sh`).
    - Resource monitoring dashboard (`admin/monitor.sh`).
    - Maintenance utilities (`admin/maintenance.sh`).
    - Persistent home directories via Docker volumes.
