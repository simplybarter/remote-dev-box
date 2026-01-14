#!/usr/bin/env bash
set -euo pipefail

USER_NAME="testdev"
USER_HOME="/home/${USER_NAME}"

# Allow passing the password at runtime (recommended).
# If omitted, it will default to "testdev" for quick pilot convenience.
USER_PASSWORD="${TESTDEV_PASSWORD:-testdev}"

echo "[entrypoint] Setting password for ${USER_NAME}"
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd

# If /home is a mounted volume, ownership can be wrong on first run.
echo "[entrypoint] Ensuring ownership of ${USER_HOME}"
mkdir -p "${USER_HOME}"
chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}"

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
