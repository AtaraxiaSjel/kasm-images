#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE="${1:-zen}"
BASE_IMAGE="${BASE_IMAGE:-core-ubuntu-jammy}"
REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-}"
TAGS="${TAGS:-rolling-weekly}"
BASE_TAG="${BASE_TAG:-$(bash "$SCRIPT_DIR/detect-latest-core-tag.sh" "$BASE_IMAGE")}"

if [ -z "$OWNER" ]; then
  echo "ERROR: OWNER env var is required (e.g. OWNER=myghuser)" >&2
  exit 1
fi

DOCKERFILE="dockerfile-kasm-${IMAGE}"
if [ "$IMAGE" == "zen-mintcifra" ]; then
  DOCKERFILE="dockerfile-kasm-zen-mintcifra"
fi

if [ ! -f "$ROOT_DIR/$DOCKERFILE" ]; then
  echo "ERROR: dockerfile not found: $DOCKERFILE" >&2
  exit 1
fi

TAG_ARGS=()
IFS=',' read -r -a taglist <<< "$TAGS"
for t in "${taglist[@]}"; do
  TAG_ARGS+=("-t" "${REGISTRY}/${OWNER}/kasm-${IMAGE}:${t}")
done

echo "Building kasm-${IMAGE} with BASE_IMAGE=$BASE_IMAGE BASE_TAG=$BASE_TAG"
echo "Tags: ${TAG_ARGS[*]}"

docker build \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  --build-arg BASE_TAG="$BASE_TAG" \
  -f "$ROOT_DIR/$DOCKERFILE" \
  "${TAG_ARGS[@]}" \
  "$ROOT_DIR"

echo "Build successful: ${REGISTRY}/${OWNER}/kasm-${IMAGE}"
