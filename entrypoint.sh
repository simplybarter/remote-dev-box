#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${USER_NAME:-testdev}"
USER_HOME="/home/${USER_NAME}"

# Allow passing the password at runtime (recommended).
# If omitted, it will default to "testdev" or the username for convenience.
USER_PASSWORD="${TESTDEV_PASSWORD:-${USER_NAME}}"

echo "[entrypoint] Preparing environment for user: ${USER_NAME}"

# 1. Create User if missing
if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
    echo "[entrypoint] User ${USER_NAME} not found. Creating..."
    # Create user with bash/zsh, add to sudo group
    useradd -m -s /bin/bash -G sudo "${USER_NAME}"
    
    # Set default password
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
else
    echo "[entrypoint] User ${USER_NAME} exists. Updating password..."
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
fi

# 2. Setup Home Directory
echo "[entrypoint] Setting up home directory at ${USER_HOME}"
mkdir -p "${USER_HOME}"

# Create .xsession for RDP if missing
if [ ! -f "${USER_HOME}/.xsession" ]; then
    echo "xfce4-session" > "${USER_HOME}/.xsession"
fi

# copy zsh config if zsh is installed and config missing
if [ -f "/root/.zshrc" ] && [ ! -f "${USER_HOME}/.zshrc" ]; then
     cp /root/.zshrc "${USER_HOME}/" || true
fi

# Ensure ownership (recursive chown can be slow on large volumes, but needed for new users)
chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}"

# 3. Start Services
# Start system dbus (needed by many desktop components)
echo "[entrypoint] Starting dbus"
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# XRDP runtime dirs
mkdir -p /var/run/xrdp /var/run/xrdp/sockdir
chmod 0755 /var/run/xrdp /var/run/xrdp/sockdir

echo "[entrypoint] Starting xrdp-sesman"
xrdp-sesman &

echo "[entrypoint] Starting xrdp (foreground)"
exec xrdp --nodaemon
