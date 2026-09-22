#!/bin/bash
# Backup FreePBX Docker volumes to timestamped tarballs.
# Usage:
#   ./backup.sh [-o DIR] [volume ...]
# Examples:
#   ./backup.sh                                   # backs up all freepbx_* volumes to ./backup
#   ./backup.sh -o /mnt/nas freepbx_db_prod      # custom dir + single volume
#
# Notes:
# - Uses a throwaway alpine container; the stack keeps running.
# - For a crash-consistent DB backup, stop the container first
#   (e.g. `docker compose -f docker-compose.prod.yml stop`).

set -e

OUT_DIR="./backup"
VOLUMES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out)
            OUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,12p' "$0"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1 (see --help)" >&2
            exit 1
            ;;
        *)
            VOLUMES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#VOLUMES[@]} -eq 0 ]]; then
    # Default: every local volume with "freepbx" in its name
    mapfile -t VOLUMES < <(docker volume ls --format "{{.Name}}" | grep -i freepbx || true)
fi

if [[ ${#VOLUMES[@]} -eq 0 ]]; then
    echo "No freepbx volumes found." >&2
    exit 1
fi

mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"

for vol in "${VOLUMES[@]}"; do
    if ! docker volume inspect "$vol" > /dev/null 2>&1; then
        echo "SKIP: volume $vol does not exist" >&2
        continue
    fi
    dest="$OUT_DIR/${vol}-${STAMP}.tar.gz"
    echo "Backing up $vol -> $dest"
    docker run --rm \
        -v "$vol:/source:ro" \
        -v "$(cd "$OUT_DIR" && pwd):/backup" \
        alpine tar czf "/backup/$(basename "$dest")" -C /source .
done

echo "Done. Backups in $OUT_DIR"
