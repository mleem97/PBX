#!/bin/bash
# Restore a FreePBX Docker volume from a backup.sh tarball.
# Usage:
#   ./restore.sh [-y] <backup.tar.gz> <volume>
# Example:
#   ./restore.sh backup/freepbx_db_prod-20260921-120000.tar.gz freepbx_db_prod
#
# Notes:
# - The volume is emptied before restore (use -y to skip confirmation).
# - Stop the container using the volume first to avoid inconsistent state:
#     docker compose -f docker-compose.prod.yml stop
#   ... then start it again after restore.

set -e

ASSUME_YES=0
if [[ "${1:-}" == "-y" ]]; then
    ASSUME_YES=1
    shift
fi

ARCHIVE="${1:?Usage: $0 [-y] <backup.tar.gz> <volume>}"
VOLUME="${2:?Usage: $0 [-y] <backup.tar.gz> <volume>}"

if [[ ! -f "$ARCHIVE" ]]; then
    echo "Archive not found: $ARCHIVE" >&2
    exit 1
fi

if ! docker volume inspect "$VOLUME" > /dev/null 2>&1; then
    echo "Creating volume $VOLUME"
    docker volume create "$VOLUME" > /dev/null
fi

if [[ "$ASSUME_YES" -ne 1 ]]; then
    echo "This will DELETE all data in volume '$VOLUME' and restore from:"
    echo "  $ARCHIVE"
    read -r -p "Continue? [y/N] " answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

ARCHIVE_ABS="$(cd "$(dirname "$ARCHIVE")" && pwd)/$(basename "$ARCHIVE")"
echo "Restoring $ARCHIVE_ABS -> $VOLUME"
docker run --rm \
    -v "$VOLUME:/target" \
    -v "$(dirname "$ARCHIVE_ABS"):/backup:ro" \
    alpine sh -c "find /target -mindepth 1 -delete; tar xzf /backup/$(basename "$ARCHIVE_ABS") -C /target"

echo "Done. Restart the container to use the restored volume."
