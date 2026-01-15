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


usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dockerfile <path>   Specify a custom Dockerfile path"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "This script rebuilds the base image and updates all user containers."
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dockerfile) CUSTOM_DOCKERFILE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

USED_DOCKERFILE="${CUSTOM_DOCKERFILE:-$DEFAULT_DOCKERFILE}"

# Auto-initialize Dockerfile if missing (First Run Scenario)
if [[ "$USED_DOCKERFILE" == "$DEFAULT_DOCKERFILE" ]] && [[ ! -f "$DEFAULT_DOCKERFILE" ]]; then
    EXAMPLE_DOCKERFILE="$PROJECT_ROOT/dockerfile.example"
    if [[ -f "$EXAMPLE_DOCKERFILE" ]]; then
        echo "Creating initial Dockerfile from dockerfile.example..."
        cp "$EXAMPLE_DOCKERFILE" "$DEFAULT_DOCKERFILE"
    else
        echo "ERROR: Neither dockerfile nor dockerfile.example found!"
        exit 1
    fi
fi

# Permissions Enforcement (For fresh clones)
echo "Enforcing file permissions..."
chmod 755 "$PROJECT_ROOT/entrypoint.sh" "$PROJECT_ROOT/admin/"*.sh
if [ -f "$CONFIG_FILE" ]; then chmod 600 "$CONFIG_FILE"; fi
if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then chmod 600 "$PROJECT_ROOT/docker-compose.yml"; fi
if [ -d "$PROJECT_ROOT/backups" ]; then chmod 700 "$PROJECT_ROOT/backups"; fi
if [ -d "$PROJECT_ROOT/logs" ]; then chmod 755 "$PROJECT_ROOT/logs"; fi


# Setup Logging
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/build-${TIMESTAMP}.log"

echo "=== Starting Global Update Deployment ==="
echo "Project Root: $PROJECT_ROOT"
echo "Using Dockerfile: $USED_DOCKERFILE"
echo "Logging to: $LOG_FILE"

# Redirect all future output to both stdout/stderr AND the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# 1. Rebuild the master image
echo "[1/3] Rebuilding Base Image ($BASE_IMAGE_NAME)..."
docker build --progress=plain -t "$BASE_IMAGE_NAME" -f "$USED_DOCKERFILE" "$PROJECT_ROOT"

# 2. Iterate through all users
if [[ ! -f "$CONFIG_FILE" ]] || [[ ! -s "$CONFIG_FILE" ]]; then
    echo "No users found in $CONFIG_FILE. Build complete, nothing to deploy."
    exit 0
fi

echo "[2/3] Updating containers..."
while IFS=: read -r user port password; do
    # Fallback if password is empty (migration support)
    pass="${password:-$user}"
    
    echo "Processing User: $user (Port $port)..."
    
    # 2a. Stop and Remove old container
    docker stop "dev-${user}" >/dev/null 2>&1 || true
    docker rm "dev-${user}" >/dev/null 2>&1 || true
    
    # 2b. Start new container (reattaching same volume)
    docker run -d \
        --name "dev-${user}" \
        --restart unless-stopped \
        -p "${port}:3389" \
        -v "remote_dev_home_${user}:/home/${user}" \
        -e "USER_NAME=${user}" \
        -e "TESTDEV_PASSWORD=${pass}" \
        --shm-size="2gb" \
        "$BASE_IMAGE_NAME" >/dev/null
        
    echo "  -> Updated dev-${user} successfully."
done < "$CONFIG_FILE"

echo "[3/3] Deployment Complete!"
echo "All users are now running the latest image version."
