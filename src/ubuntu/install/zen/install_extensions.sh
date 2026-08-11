#!/usr/bin/env bash
set -ex

ZEN_BASE=/opt/zen
EXTENSION_DIR=${ZEN_BASE}/distribution/extensions
mkdir -p "$EXTENSION_DIR"

UBO_GUID=uBlock0@raymondhill.net
UBO_FILE="https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"

DR_GUID=addon@darkreader.org
DR_FILE="https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"

echo "Installing uBlock Origin"
curl -sL "$UBO_FILE" -o "${EXTENSION_DIR}/${UBO_GUID}.xpi"

echo "Installing Dark Reader"
curl -sL "$DR_FILE" -o "${EXTENSION_DIR}/${DR_GUID}.xpi"

chown -R root:root "$EXTENSION_DIR"

ZEN_BIN=/opt/zen/zen
ZEN_PROFILE_BASE="$HOME/.config/zen"
ZEN_PROFILE_PATH="$ZEN_PROFILE_BASE/kasm"

mkdir -p "$ZEN_PROFILE_PATH"

/bin/bash -c "HOME=$HOME '$ZEN_BIN' --headless </dev/null >/dev/null 2>&1 &"
ZEN_PID=$!
sleep 12
kill $ZEN_PID 2>/dev/null || true
pkill -x zen 2>/dev/null || true

rm -f "$ZEN_PROFILE_PATH/sessionstore.jsonlz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/recovery.jsonlz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/recovery.baklz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/previous.jsonlz4" 2>/dev/null || true

chown -R 1000:1000 "$ZEN_PROFILE_BASE"
chmod -R u+rwX,go+rX "$ZEN_PROFILE_BASE"

ls -la "${EXTENSION_DIR}/"
