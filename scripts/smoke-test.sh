#!/usr/bin/env bash
# Runs a kasm-zen image and verifies it works: KasmVNC must answer its health
# endpoint and the Zen browser process must be alive. Tears the container down
# afterwards.
# Usage: OWNER=myghuser [SMOKE_TAG=rolling-weekly] [SMOKE_PORT=6901] scripts/smoke-test.sh [zen|zen-mintcifra]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE="${1:-${IMAGE:-zen}}"
REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-}"
TAG="${SMOKE_TAG:-rolling-weekly}"
PORT="${SMOKE_PORT:-6901}"
VNC_PW="${VNC_PW:-kasmtest}"

if [ -z "$OWNER" ]; then
  echo "ERROR: OWNER env var is required (e.g. OWNER=myghuser)" >&2
  exit 1
fi

FULL_IMAGE="${REGISTRY}/${OWNER}/kasm-${IMAGE}:${TAG}"
CONTAINER="kasm-smoke-${IMAGE}"
HEALTH_URL="https://127.0.0.1:${PORT}/api/__healthcheck"

# Remove the container whether the test passes or fails
cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Smoke testing ${FULL_IMAGE}"
docker run -d \
  --name "$CONTAINER" \
  -p "${PORT}:6901" \
  -e "VNC_PW=${VNC_PW}" \
  --shm-size=512m \
  "$FULL_IMAGE" >/dev/null

echo "Waiting for KasmVNC to serve on port ${PORT}..."
READY=false
for i in $(seq 1 60); do
  # A 401 (auth required) or 2xx proves the websockify/VNC service is up and answering.
  CODE=$(curl --connect-timeout 3 -sk -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || true)
  case "$CODE" in
    401|2[0-9][0-9])
      READY=true
      echo "KasmVNC is up (HTTP ${CODE})."
      break
      ;;
  esac
  sleep 2
done

if [ "$READY" != "true" ]; then
  echo "FAILED: container did not become ready at ${HEALTH_URL}" >&2
  docker logs "$CONTAINER" 2>&1 | tail -n 40 || true
  exit 1
fi

echo "Verifying Zen browser process is running..."
ZEN_RUNNING=false
for i in $(seq 1 30); do
  # Either process name variant proves the custom_startup loop is working
  if docker exec "$CONTAINER" pgrep -x zen >/dev/null 2>&1 || \
     docker exec "$CONTAINER" pgrep -x zen-bin >/dev/null 2>&1; then
    ZEN_RUNNING=true
    echo "Zen process confirmed running."
    break
  fi
  sleep 2
done

if [ "$ZEN_RUNNING" != "true" ]; then
  echo "FAILED: Zen browser process not detected in container" >&2
  docker logs "$CONTAINER" 2>&1 | tail -n 40 || true
  exit 1
fi

echo "Smoke test passed for ${FULL_IMAGE}"