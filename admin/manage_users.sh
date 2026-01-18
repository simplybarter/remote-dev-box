#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/users.conf"
BASE_IMAGE_NAME="remote-dev-image"
START_PORT=3400

# Ensure config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    touch "$CONFIG_FILE"
fi


usage() {
    echo "Usage: $0 {add|remove|list|backup|update_password} [args...]"
    echo "  add <username> [password]      - Create a new user container (generates secure password if omitted)"
    echo "  remove <username> [--purge]    - Stop and remove a user container"
    echo "  list                           - List active users and ports"
    echo "  backup <username>              - Backup user home directory"
    echo "  update_password <user> <pass>  - Update user password and restart container"
    exit 1
}

get_next_port() {
    local last_port
    last_port=$(cut -d: -f2 "$CONFIG_FILE" | sort -rn | head -n1)
    if [[ -z "$last_port" ]]; then
        echo "$START_PORT"
    else
        echo $((last_port + 1))
    fi
}

add_user() {
    local user="$1"
    local password="$2"

    # Generate secure password if not provided
    if [[ -z "$password" ]]; then
        password=$(openssl rand -base64 12)
        echo "Auto-generating secure password for '$user'..."
    fi
    
    if grep -q "^${user}:" "$CONFIG_FILE"; then
        echo "Error: User '$user' already exists."
        exit 1
    fi

    echo "Building base image if needed..."
     # Use robust PROJECT_ROOT path
    docker build -t "$BASE_IMAGE_NAME" -f "$PROJECT_ROOT/dockerfile" "$PROJECT_ROOT"

    local port
    port=$(get_next_port)
    
    echo "Creating user '$user' on port $port..."
    
    # Create the volume first
    docker volume create "remote_dev_home_${user}" >/dev/null

    # Run the container
    docker run -d \
        --name "dev-${user}" \
        --restart unless-stopped \
        -p "${port}:3389" \
        -v "remote_dev_home_${user}:/home/${user}" \
        -e "USER_NAME=${user}" \
        -e "TESTDEV_PASSWORD=${password}" \
        --shm-size="2gb" \
        "$BASE_IMAGE_NAME"

    # Save to config (user:port:password)
    echo "${user}:${port}:${password}" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "${user}:${port}:${password}" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "User '$user' created!"
    echo "  -> Port: $port"
    echo "  -> Password: $password"
}

remove_user() {
    local user="$1"
    local purge="${2:-false}"
    
    if ! grep -q "^${user}:" "$CONFIG_FILE"; then
        echo "Error: User '$user' not found."
        exit 1
    fi

    echo "Stopping container dev-${user}..."
    docker stop "dev-${user}" || true
    docker rm "dev-${user}" || true

    # Remove from config
    grep -v "^${user}:" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    echo "User '$user' removed."
    
    if [[ "$purge" == "true" ]]; then
        echo "Purging data volume 'remote_dev_home_${user}'..."
        docker volume rm "remote_dev_home_${user}" || true
        echo "Data volume purged."
    else
        echo "Note: Data volume 'remote_dev_home_${user}' was NOT deleted. Remove manually if needed: docker volume rm remote_dev_home_${user}"
    fi
}

update_password() {
    local user="$1"
    local new_password="$2"
    
    if [[ -z "$user" ]] || [[ -z "$new_password" ]]; then
        echo "Usage: $0 update_password <username> <new_password>"
        exit 1
    fi

    if ! grep -q "^${user}:" "$CONFIG_FILE"; then
        echo "Error: User '$user' not found."
        exit 1
    fi
     
    # Get existing port
    local port
    port=$(grep "^${user}:" "$CONFIG_FILE" | cut -d: -f2)

    echo "Updating password for '$user'..."
    
    # Update Config File
    grep -v "^${user}:" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    echo "${user}:${port}:${new_password}" >> "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    echo "Restarting container with new password..."
    docker stop "dev-${user}" >/dev/null
    docker rm "dev-${user}" >/dev/null
    
    docker run -d \
        --name "dev-${user}" \
        --restart unless-stopped \
        -p "${port}:3389" \
        -v "remote_dev_home_${user}:/home/${user}" \
        -e "USER_NAME=${user}" \
        -e "TESTDEV_PASSWORD=${new_password}" \
        --shm-size="2gb" \
        "$BASE_IMAGE_NAME" >/dev/null
        
    echo "Password updated successfully!"
}

list_users() {
    echo "Active Users:"
    echo "USER       PORT    STATUS"
    echo "-------------------------"
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo "(No users found)"
        return
    fi
    
    while IFS=: read -r user port password; do
        local status
        status=$(docker inspect -f '{{.State.Status}}' "dev-${user}" 2>/dev/null || echo "stopped/missing")
        printf "%-10s %-7s %s\n" "$user" "$port" "$status"
    done < "$CONFIG_FILE"
}

backup_user() {
    local user="$1"
    local volume="remote_dev_home_${user}"
    
    # Setup Backup Directory
    local backup_dir="$PROJECT_ROOT/backups"
    mkdir -p "$backup_dir"
    chmod 700 "$backup_dir"
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="backup_${user}_${timestamp}.tar.gz"

    echo "Backing up volume '$volume' to $backup_dir/$backup_file..."
    
    docker run --rm \
        -v "$volume":/source \
        -v "$backup_dir":/backup \
        ubuntu:24.04 \
        tar czf "/backup/$backup_file" -C /source .
        
    chmod 600 "$backup_dir/$backup_file"
    echo "Backup complete: $backup_dir/$backup_file"
}

case "${1:-}" in
    add)
        if [[ -z "${2:-}" ]]; then usage; fi
        add_user "$2" "${3:-}"
        ;;
    remove)
        if [[ -z "${2:-}" ]]; then usage; fi
        if [[ "${2:-}" == "--purge" ]]; then
             if [[ -z "${3:-}" ]]; then usage; fi
             remove_user "$3" "true"
        elif [[ "${3:-}" == "--purge" ]]; then
             remove_user "$2" "true"
        else
             remove_user "$2" "false"
        fi
        ;;
    list)
        list_users
        ;;
    backup)
        if [[ -z "${2:-}" ]]; then usage; fi
        backup_user "$2"
        ;;
    update_password)
        if [[ -z "${2:-}" ]]; then usage; fi
        update_password "$2" "${3:-}"
        ;;
    -h|--help)
        usage
        ;;
    *)
        usage
        ;;
esac
