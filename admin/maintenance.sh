#!/bin/bash
set -euo pipefail

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
