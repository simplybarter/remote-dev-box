#!/bin/bash
set -euo pipefail


if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0"
    echo ""
    echo "This script cleans up Docker resources to free up disk space."
    echo "It performs:"
    echo "  1. docker system prune -f (containers, networks, dangling images)"
    echo "  2. docker builder prune -a -f (build cache)"
    echo "  3. docker volume prune -f (unused volumes)"
    exit 0
fi

echo "=== Docker Space Maintenance ==="

echo "WARNING: This will remove stopped containers, unused networks, dangling images, and UNUSED VOLUMES."
echo "Active user data volumes (attached to running containers) will be SAFE."
echo "Press Ctrl+C to cancel in 5 seconds..."
sleep 5

echo "[1/3] Pruning System (Containers, Networks, Dangling Images)..."
docker system prune -f

echo "[2/3] Pruning Build Cache..."
docker builder prune -a -f

echo "[3/3] Pruning Unused Volumes..."
# This is critical: It deletes volumes not currently mounted by any container.
docker volume prune -f

echo "=== Disk Usage After Cleanup ==="
df -h / | tail -n 1
docker system df
