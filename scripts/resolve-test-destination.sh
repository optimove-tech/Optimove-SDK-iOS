#!/bin/bash
# resolve-test-destination.sh [PREFERRED_DEVICE_NAME]
#
# Emits an xcodebuild -destination specifier for an iOS simulator that actually
# exists on this machine.
#
# A name-only destination such as "platform=iOS Simulator,name=iPhone 15" is
# resolved by xcodebuild against OS:latest. When the newest installed runtime has
# no device by that name, xcodebuild fails with "Unable to find a device matching
# the provided destination specifier" instead of falling back to an older runtime.
# Resolving to a concrete UDID here avoids depending on which runtimes happen to
# be installed.
#
# Set TEST_DESTINATION to bypass resolution entirely.

set -o pipefail
set -e

if [ -n "$TEST_DESTINATION" ]; then
    echo "$TEST_DESTINATION"
    exit 0
fi

PREFERRED_NAME="${1:-}"

# "<os-version>|<device-name>|<udid>" for every booted-or-bootable iOS simulator,
# oldest runtime first.
DEVICES=$(
    xcrun simctl list devices available |
        awk '
            /^-- iOS /              { os = $3; next }
            /^-- /                  { os = "";  next }
            os == ""                { next }
            match($0, /\(([0-9A-Fa-f-]{36})\)/) {
                udid = substr($0, RSTART + 1, RLENGTH - 2)
                name = $0
                sub(/^[[:space:]]+/, "", name)
                sub(/[[:space:]]+\([0-9A-Fa-f-]{36}\).*$/, "", name)
                print os "|" name "|" udid
            }
        ' | sort -t'|' -k1,1V
)

if [ -z "$DEVICES" ]; then
    echo "No available iOS simulators found. Install a simulator runtime via Xcode > Settings > Components." 1>&2
    exit 1
fi

# Prefer the requested device on the newest runtime that has it, then any iPhone,
# then whatever is left.
MATCH=""
if [ -n "$PREFERRED_NAME" ]; then
    MATCH=$(echo "$DEVICES" | awk -F'|' -v n="$PREFERRED_NAME" '$2 == n' | tail -1)
fi
if [ -z "$MATCH" ]; then
    MATCH=$(echo "$DEVICES" | awk -F'|' '$2 ~ /^iPhone/' | tail -1)
fi
if [ -z "$MATCH" ]; then
    MATCH=$(echo "$DEVICES" | tail -1)
fi

OS_VERSION=$(echo "$MATCH" | cut -d'|' -f1)
DEVICE_NAME=$(echo "$MATCH" | cut -d'|' -f2)
UDID=$(echo "$MATCH" | cut -d'|' -f3)

if [ -n "$PREFERRED_NAME" ] && [ "$DEVICE_NAME" != "$PREFERRED_NAME" ]; then
    echo "Note: '$PREFERRED_NAME' is not available; using '$DEVICE_NAME' (iOS $OS_VERSION)." 1>&2
fi

echo "platform=iOS Simulator,id=$UDID"
