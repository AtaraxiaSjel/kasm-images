#!/usr/bin/env bash
# Downloads the latest Zen Browser release, installs it to /opt/zen and
# prepares a locked "kasm" profile (default search engine, prefs, no wizard).
set -ex

ARCH=$(arch)
case "$ARCH" in
  x86_64) ARCH="x86_64" ;;
  aarch64) ARCH="aarch64" ;;
esac

echo "Install Zen Browser"

# Download the latest release tarball from GitHub
ZEN_TARBALL="zen.linux-${ARCH}.tar.xz"

curl -sL \
  "https://github.com/zen-browser/desktop/releases/latest/download/${ZEN_TARBALL}" \
  -o /tmp/zen.tar.xz

tar -C /opt -xJf /tmp/zen.tar.xz
rm -f /tmp/zen.tar.xz

ZEN_BIN=/opt/zen/zen
ZEN_DIR=/opt/zen

if [ ! -x "$ZEN_BIN" ]; then
  echo "ERROR: zen binary not found" >&2
  exit 1
fi

# Use the system PKCS#11 trust module so system CAs are honored by the browser
ln -sf /usr/lib/$(arch)-linux-gnu/pkcs11/p11-kit-trust.so $ZEN_DIR/libnssckbi.so

chown -R root:root $ZEN_DIR

# Fix the desktop entry copied by the base image to point at the Zen binary/icon
touch $HOME/Desktop/zen.desktop
sed -i \
  -e 's!Name=.*!Name=Zen Browser!' \
  -e 's!Exec=.*!Exec='$ZEN_DIR'/zen %u!' \
  -e 's!Icon=.*!Icon='$ZEN_DIR'/browser/chrome/icons/default/default128.png!' \
  -e 's!Comment=.*!Comment=Web Browser!' \
  $HOME/Desktop/zen.desktop
chmod +x $HOME/Desktop/zen.desktop

mkdir -p /usr/share/icons
cp $ZEN_DIR/browser/chrome/icons/default/default128.png /usr/share/icons/zen.png 2>/dev/null || true

# Pre-create the "kasm" profile so it is picked as default instead of the
# auto-generated one on first launch
ZEN_PROFILE_BASE="$HOME/.config/zen"
ZEN_PROFILE_PATH="$ZEN_PROFILE_BASE/kasm"
ZEN_PROFILES_INI="$ZEN_PROFILE_BASE/profiles.ini"

mkdir -p "$ZEN_PROFILE_BASE"

chown -R 0:0 "$HOME/.config" 2>/dev/null || chown -R 0:0 "$HOME"

"$ZEN_BIN" --headless -CreateProfile "kasm $ZEN_PROFILE_PATH" 2>/dev/null || true

# Create the profile section and lock it as default
mkdir -p "$ZEN_PROFILE_PATH"

# Run headless once so profiles.ini is generated and persisted
/bin/bash -c "HOME=$HOME '$ZEN_BIN' --headless </dev/null >/dev/null 2>&1 &"
ZEN_PID=$!
for i in $(seq 1 60); do
  grep -q '^\[Install' "$ZEN_PROFILES_INI" 2>/dev/null && break
  sleep 1
done
sleep 2
kill $ZEN_PID 2>/dev/null || true
pkill -x zen 2>/dev/null || true

if ! grep -q '^Default=kasm' "$ZEN_PROFILES_INI" 2>/dev/null; then
  INSTALL_SECTION=$(grep -oE '^\[Install[0-9A-F]+\]' "$ZEN_PROFILES_INI" | head -n1)
  if [ -n "$INSTALL_SECTION" ]; then
    sed -i "/^[[:space:]]*Default=/d;/^[[:space:]]*Locked=/d" "$ZEN_PROFILES_INI"
    awk -v sect="$INSTALL_SECTION" '
      $0==sect { in_sect=1; print; print "Default=kasm"; print "Locked=1"; next; }
      in_sect && /^\[/ { in_sect=0; }
      in_sect && (/^Default=/ || /^Locked=/) { next; }
      { print }
    ' "$ZEN_PROFILES_INI" > "$ZEN_PROFILES_INI.tmp" && mv "$ZEN_PROFILES_INI.tmp" "$ZEN_PROFILES_INI"
  else
    echo "NOTICE: no install section found; appending generic section" >&2
    cat >> "$ZEN_PROFILES_INI" <<EOL

[Install0000000000000000]
Default=kasm
Locked=1
EOL
  fi
fi

# Persist the frozen first-run prefs; they ship with the image
echo 'user_pref("security.sandbox.warn_unprivileged_namespaces", false);' > "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("browser.aboutwelcome.enabled", false);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("zen.welcome-screen.seen", true);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("datareporting.policy.dataSubmissionEnabled", false);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("datareporting.policy.firstRunURL", "");' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("browser.startup.page", 1);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("browser.startup.homepage", "about:blank");' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("zen.view.window.scheme", 0);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("startup.homepage_welcome_url", "about:blank");' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("browser.shell.checkDefaultBrowser", false);' >> "$ZEN_PROFILE_PATH/user.js"
echo 'user_pref("startup.homepage_welcome_url.additional", "");' >> "$ZEN_PROFILE_PATH/user.js"

# Drop any leftover session state so the browser always opens blank
rm -f "$ZEN_PROFILE_PATH/sessionstore.jsonlz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/recovery.jsonlz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/recovery.baklz4" \
      "$ZEN_PROFILE_PATH/sessionstore-backups/previous.jsonlz4" 2>/dev/null || true

# Lock DuckDuckGo as the default search engine via enterprise policy
mkdir -p $ZEN_DIR/distribution
cat > $ZEN_DIR/distribution/policies.json <<EOL
{
  "policies": {
    "SearchEngines": {
      "Default": "DuckDuckGo"
    }
  }
}
EOL

chown -R 1000:1000 "$ZEN_PROFILE_BASE"
chmod -R u+rwX,go+rX "$ZEN_PROFILE_BASE"

chown 1000:1000 "$HOME/Desktop/zen.desktop"

find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \; 2>/dev/null || true
