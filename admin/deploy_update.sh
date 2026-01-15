#!/bin/bash
set -euo pipefail

# Configuration
# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/users.conf"
BASE_IMAGE_NAME="remote-dev-image"
DEFAULT_DOCKERFILE="$PROJECT_ROOT/dockerfile"
CUSTOM_DOCKERFILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dockerfile) CUSTOM_DOCKERFILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

USED_DOCKERFILE="${CUSTOM_DOCKERFILE:-$DEFAULT_DOCKERFILE}"

echo "=== Starting Global Update Deployment ==="
echo "Project Root: $PROJECT_ROOT"
echo "Using Dockerfile: $USED_DOCKERFILE"

# 1. Rebuild the master image
echo "[1/3] Rebuilding Base Image ($BASE_IMAGE_NAME)..."
docker build -t "$BASE_IMAGE_NAME" -f "$USED_DOCKERFILE" "$PROJECT_ROOT"

# 2. Iterate through all users
if [[ ! -f "$CONFIG_FILE" ]] || [[ ! -s "$CONFIG_FILE" ]]; then
    echo "No users found in $CONFIG_FILE. Build complete, nothing to deploy."
    exit 0
fi

echo "[2/3] Updating containers..."
while IFS=: read -r user port; do
    echo "Processing User: $user (Port $port)..."
    
    # 2a. Stop and Remove old container
    docker stop "dev-${user}" >/dev/null 2>&1 || true
    docker rm "dev-${user}" >/dev/null 2>&1 || true
    
    # 2b. Start new container (reattaching same volume)
    # Note: We re-read the environment variable logic if you stored passwords in config, 
    # but for now we default to user-as-password or env var if we tracked it.
    # To keep it simple, we assume the default password or you'd need to store password in users.conf too.
    # For now, let's keep the existing password logic (defaulting to username or generic testdev).
    
    docker run -d \
        --name "dev-${user}" \
        --restart unless-stopped \
        -p "${port}:3389" \
        -v "remote_dev_home_${user}:/home/${user}" \
        -e "USER_NAME=${user}" \
        -e "TESTDEV_PASSWORD=${user}" \
        --shm-size="2gb" \
        "$BASE_IMAGE_NAME" >/dev/null
        
    echo "  -> Updated dev-${user} successfully."
done < "$CONFIG_FILE"

echo "[3/3] Deployment Complete!"
echo "All users are now running the latest image version."
