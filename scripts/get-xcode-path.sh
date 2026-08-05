#!/bin/bash
# get-xcode-path.sh ARG
#  - ARG: The version number or path

set -o pipefail
set -e

ROOT_PATH=$(dirname "${0}")/..

XCODE_APPS_FINDER=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'")
XCODE_APPS_FALLBACK=$(find /Applications -iname 'Xcode*.app' -maxdepth 1)
XCODE_APPS=$(echo -e "$XCODE_APPS_FINDER\n$XCODE_APPS_FALLBACK" | sort | uniq)
PLIST_BUDDY="/usr/libexec/PlistBuddy"
XCODE_ARG=$1

function get_plist_value() {
    "$PLIST_BUDDY" -c "Print :$2" "$1/Contents/Info.plist"
}

function get_version() {
    APP_NAME=$(get_plist_value "$1" "CFBundleName")
    if [[ "$APP_NAME" == "Xcode" ]]; then
        echo $(get_plist_value "$1" "CFBundleShortVersionString")
    else
        echo ""
    fi
}

if [ -d "$XCODE_ARG" ]; then
    echo $2
    exit 0
fi

for APP in $XCODE_APPS; do
    APP_VERSION=$(get_version $APP)
    if [ $XCODE_ARG = $APP_VERSION ]; then
        echo $APP
        exit 0
    fi
done

echo "Requested Xcode $XCODE_ARG not found. Available versions: " 1>&2

for APP in $XCODE_APPS; do
    APP_VERSION=$(get_version $APP)
    echo "$APP_VERSION: $APP" 1>&2
done

# Pinning an Xcode version that isn't installed should not make every target
# unrunnable. Fall back to the active toolchain and say so, unless the caller
# asked for a strict match (CI does, so a missing pinned Xcode fails loudly).
if [ -n "$XCODE_STRICT" ] && [ "$XCODE_STRICT" != "0" ]; then
    echo "XCODE_STRICT is set, refusing to fall back." 1>&2
    exit 1
fi

# Keep the failure non-fatal under `set -e` so the check below reports it.
ACTIVE_XCODE=$(xcode-select -p 2>/dev/null) || true

if [ -z "$ACTIVE_XCODE" ]; then
    echo "No active Xcode found via xcode-select." 1>&2
    exit 1
fi

echo "Falling back to the active toolchain: $ACTIVE_XCODE" 1>&2
echo "Pass XCODE=<version> to pick another, or XCODE_STRICT=1 to fail instead." 1>&2
echo "$ACTIVE_XCODE"
