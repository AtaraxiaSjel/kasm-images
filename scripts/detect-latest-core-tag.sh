#!/usr/bin/env bash
# Resolves the newest "X.Y.Z-rolling-weekly" tag for a Kasm base image from
# Docker Hub. Honors an explicit BASE_TAG override. Used by build.sh and CI.
set -euo pipefail

BASE_IMAGE="${1:-core-ubuntu-jammy}"
OVERRIDE="${BASE_TAG:-}"

# An explicit BASE_TAG always wins over auto-detection
if [ -n "$OVERRIDE" ]; then
  echo "$OVERRIDE"
  exit 0
fi

# Pull the tag list from the Docker Hub registry API
TAGS=$(curl -sL \
  "https://hub.docker.com/v2/repositories/kasmweb/${BASE_IMAGE}/tags?page_size=100")

# Pick the highest versioned rolling-weekly tag (plain "rolling" is ignored)
LATEST=$(echo "$TAGS" \
  | tr ',' '\n' \
  | grep -oE '"name":"[0-9][0-9.]*-rolling-weekly"' \
  | sed -E 's/"name":"([^"]+)"/\1/' \
  | sort -V \
  | tail -n 1)

if [ -z "$LATEST" ]; then
  echo "ERROR: could not detect rolling-weekly tag for kasmweb/${BASE_IMAGE}" >&2
  exit 1
fi

echo "$LATEST"