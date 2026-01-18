#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${USER_NAME:-testdev}"
USER_HOME="/home/${USER_NAME}"

# Allow passing the password at runtime (recommended).
USER_PASSWORD="${TESTDEV_PASSWORD:-${USER_NAME}}"

echo "[entrypoint] Preparing environment for user: ${USER_NAME}"

# 1. Create User if missing
if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
    echo "[entrypoint] User ${USER_NAME} not found. Creating..."
    # Create user with bash, add to sudo group
    useradd -m -s /bin/bash -G sudo "${USER_NAME}"
    
    # Set password
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
    
    # Allow sudo without password for the user
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USER_NAME}"
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

# Ensure ownership
chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}"

# 3. Start Services
# Start system dbus
echo "[entrypoint] Starting dbus"
mkdir -p /var/run/dbus
rm -f /var/run/dbus/dbus.pid
dbus-daemon --system --fork

# Force update icon cache if adwaita is installed
if [ -d /usr/share/icons/Adwaita ]; then
    echo "[entrypoint] Updating icon cache..."
    gtk-update-icon-cache -f -t /usr/share/icons/Adwaita || true
fi

mkdir -p /var/run/xrdp /var/run/xrdp/sockdir
chmod 0755 /var/run/xrdp /var/run/xrdp/sockdir

# Generate keys if missing
if [ ! -f /etc/xrdp/rsakeys.ini ]; then
    echo "[entrypoint] Generating RSA keys..."
    xrdp-keygen xrdp auto
fi

if [ ! -f /etc/xrdp/cert.pem ] || [ ! -f /etc/xrdp/key.pem ]; then
    echo "[entrypoint] Generating TLS certificate..."
    openssl req -x509 -newkey rsa:2048 -nodes -keyout /etc/xrdp/key.pem -out /etc/xrdp/cert.pem -days 365 -subj "/CN=$(hostname)"
    # Ensure keys are readable by ssl-cert group (for xrdp)
    chown root:ssl-cert /etc/xrdp/key.pem /etc/xrdp/cert.pem
    chmod 640 /etc/xrdp/key.pem /etc/xrdp/cert.pem
fi

# Create socket dir for xrdp
if [ ! -d /run/xrdp/sockdir ]; then
    mkdir -p /run/xrdp/sockdir
fi
chmod 1777 /run/xrdp/sockdir

echo "[entrypoint] Starting xrdp-sesman"
xrdp-sesman --nodaemon &

echo "[entrypoint] Starting xrdp (foreground)"
exec xrdp --nodaemon
