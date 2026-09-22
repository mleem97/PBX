#!/bin/bash
# Boot smoke test for a FreePBX image: fresh first-boot install must reach
# supervisord with all services RUNNING and HTTP 200 on the web UI.
# Usage: ./tests/smoke.sh <image>[:tag]  (e.g. ./tests/smoke.sh mleem97/lnxr-freepbx:17-alpine)
#
# Exit 0 = healthy, non-zero = failure. Cleans up its container afterwards.

set -u

IMAGE="${1:?Usage: $0 <image>[:tag]}"
NAME="smoke-$(date +%s)"
HTTP_PORT="${SMOKE_HTTP_PORT:-18080}"
TIMEOUT="${SMOKE_TIMEOUT:-600}"   # full first-boot install takes minutes

cleanup() {
    docker rm -f "$NAME" > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Starting $IMAGE as $NAME"
docker run -d --name "$NAME" -p "${HTTP_PORT}:80" "$IMAGE" > /dev/null
echo "==> Waiting for healthy supervisord (timeout ${TIMEOUT}s)..."

elapsed=0
healthy=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
    if docker exec "$NAME" supervisorctl status 2>/dev/null | grep -q "RUNNING"; then
        # all four services must be RUNNING, none FATAL/EXITED
        status="$(docker exec "$NAME" supervisorctl status 2>/dev/null)"
        if echo "$status" | grep -Eq "mysqld|asterisk|php-fpm|nginx" \
            && ! echo "$status" | grep -Eq "FATAL|BACKOFF|EXITED|UNKNOWN"; then
            running="$(echo "$status" | grep -c RUNNING)"
            if [ "$running" -ge 4 ]; then
                healthy=1
                break
            fi
        fi
    fi
    sleep 10
    elapsed=$((elapsed + 10))
done

if [ "$healthy" -ne 1 ]; then
    echo "FAIL: services not healthy within ${TIMEOUT}s"
    docker logs "$NAME" 2>&1 | tail -n 20
    exit 1
fi
echo "==> Services:"
docker exec "$NAME" supervisorctl status

echo "==> Asterisk version:"
docker exec "$NAME" asterisk -rx "core show version" 2>&1 | head -n 1

echo "==> HTTP check (expect 200 on /admin/config.php)..."
code="$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${HTTP_PORT}/admin/config.php")"
echo "HTTP: $code"
if [ "$code" != "200" ]; then
    echo "FAIL: expected HTTP 200, got $code"
    exit 1
fi

echo "SMOKE OK: $IMAGE"
