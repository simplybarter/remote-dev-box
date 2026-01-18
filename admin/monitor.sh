#!/bin/bash
set -e


if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Displays a dashboard of:"
    echo "  1. Active Containers (CPU & RAM usage)"
    echo "  2. Container Storage (Writable layer & Virtual size)"
    echo "  3. Base Image Size"
    echo "  4. Disk Usage (User Data Volumes)"
    echo ""
    exit 0
fi

echo "=============================================================================="

echo " 🟢 ACTIVE CONTAINERS (Current CPU & RAM Usage)"
echo "=============================================================================="
# --no-stream takes a single snapshot instead of a live stream
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | sed 's/^/  /'

echo ""
echo "=============================================================================="
echo " 📦 CONTAINER STORAGE (Writable Layer vs Virtual Size)"
echo "=============================================================================="
docker ps -a --filter "name=remote-dev-box-" --format "table {{.Names}}\t{{.Size}}" | sed 's/^/  /'

echo ""
echo "=============================================================================="
echo " 🖼️  BASE IMAGE SIZE"
echo "=============================================================================="
docker images "remote-dev-box-image" --format "  {{.Repository}}: {{.Size}}" || echo "  (Base image not found)"

echo ""
echo "=============================================================================="
echo " 💾 DISK USAGE (User Data Volumes)"
echo "=============================================================================="
printf "  %-40s %s\n" "USER DATA VOLUME" "SIZE"
echo "  ------------------------------------------------------------"

# We grab lines matching our volume prefix, and print Name (col 1) and Size (cols 3+4)
# Note: This relies on the standard output format of 'docker system df -v'
docker system df -v | grep "remote_dev_home" | awk '{printf "  %-40s %s%s\n", $1, $3, $4}' || echo "  (No user volumes found)"

echo ""
echo "  Note: To free up space, run ./maintenance.sh"
