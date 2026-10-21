#!/bin/sh

# =========================================================================
# One-liner execution command:
# wget -qO - https://raw.githubusercontent.com/popking159/novalerdownloader/refs/heads/main/myinstaller.sh | /bin/sh
# =========================================================================

PLUGIN_NAME="NovalerDownloader"
PKG_BASE="enigma2-plugin-extensions-novalerdownloader"
VERSION="1.1"
USERNAME="popking159"
REPO="novalerdownloader"
ARCH="all"

TMP_DIR="/var/volatile/tmp"
[ -d "$TMP_DIR" ] || TMP_DIR="/tmp"

PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/NovalerDownloader"

# =========================================================================
# Color Codes & Logging
# =========================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    # Automatically colorize based on the log tag
    case "$1" in
        *\[INFO\]*) echo -e "${CYAN}$1${NC}" ;;
        *\[OK\]*) echo -e "${GREEN}$1${NC}" ;;
        *\[WARN\]*) echo -e "${YELLOW}$1${NC}" ;;
        *\[ERROR\]*) echo -e "${RED}$1${NC}" ;;
        *) echo -e "$1" ;;
    esac
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}====================================================${NC}"
echo -e "${GREEN}         $PLUGIN_NAME UNIVERSAL INSTALLER           ${NC}"
echo -e "${GREEN}                  by MNASR                          ${NC}"
echo -e "${YELLOW}====================================================${NC}"

# 1. Verify opkg is available
if ! has_cmd opkg; then
    log "[ERROR] opkg package manager not found! This plugin requires an Enigma2 system."
    exit 1
fi
log "[INFO] Package manager detected: opkg"

# 2. Construct IPK URL
IPK_NAME="${PKG_BASE}_${VERSION}_${ARCH}.ipk"
PLUGIN_URL="https://github.com/${USERNAME}/${REPO}/raw/main/${IPK_NAME}"
TMP_FILE="$TMP_DIR/$IPK_NAME"

log "[INFO] Target Package: $IPK_NAME"

# 3. Check and Remove Existing Version
log "[INFO] Checking for previous installations..."
OLD_INSTALLED=0

if opkg status "$PKG_BASE" 2>/dev/null | grep -q "^Status:.*installed"; then
    log "[WARN]    -> Old package version detected. Uninstalling via opkg..."
    opkg remove "$PKG_BASE" --force-depends >/dev/null 2>&1
    OLD_INSTALLED=1
fi

if [ -d "$PLUGIN_PATH" ]; then
    log "[WARN]    -> Old plugin directory detected. Removing..."
    rm -rf "$PLUGIN_PATH"
    OLD_INSTALLED=1
fi

if [ $OLD_INSTALLED -eq 1 ]; then
    log "[OK]    -> Uninstallation of previous version complete."
else
    log "[INFO]    -> No previous version found."
fi

# 4. Check and Install Required Python 3 Dependencies
log "[INFO] Checking required dependencies for Python 3..."
DEPS="python3-requests python3-beautifulsoup4 python3-urllib3"

for dep in $DEPS; do
    if ! opkg status "$dep" 2>/dev/null | grep -q "^Status:.*installed"; then
        log "[WARN]    -> Installing missing dependency: $dep"
        opkg install "$dep" >/dev/null 2>&1
    else
        log "[OK]    -> $dep is already installed."
    fi
done

# 5. Download IPK Archive
log "[INFO] Downloading IPK package..."
rm -f "$TMP_FILE"

if has_cmd wget; then
    wget -q --no-check-certificate "$PLUGIN_URL" -O "$TMP_FILE"
elif has_cmd curl; then
    curl -s -k -L "$PLUGIN_URL" -o "$TMP_FILE"
fi

if [ ! -s "$TMP_FILE" ] || grep -q -i "<html" "$TMP_FILE" || grep -q "404: Not Found" "$TMP_FILE"; then
    log "[ERROR] Download failed! The package $IPK_NAME does not exist on GitHub."
    rm -f "$TMP_FILE"
    exit 1
fi

# 6. Install the IPK
log "[INFO] Installing package..."
opkg install --force-reinstall --force-overwrite "$TMP_FILE"

if [ $? -ne 0 ]; then
    log "[ERROR] Installation failed!"
    rm -f "$TMP_FILE"
    exit 1
fi

# 7. Cleanup and Finalize
rm -f "$TMP_FILE"
sync

echo -e "${YELLOW}====================================================${NC}"
echo -e "${GREEN}          $PLUGIN_NAME INSTALLATION COMPLETE        ${NC}"
echo -e "${YELLOW}====================================================${NC}"
log "[OK] Universal plugin installed successfully."

exit 0
