#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${1:-core-ubuntu-jammy}"
OVERRIDE="${BASE_TAG:-}"

if [ -n "$OVERRIDE" ]; then
  echo "$OVERRIDE"
  exit 0
fi

TAGS=$(curl -sL \
  "https://hub.docker.com/v2/repositories/kasmweb/${BASE_IMAGE}/tags?page_size=100")

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