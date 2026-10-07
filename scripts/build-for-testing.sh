#!/bin/bash

set -o pipefail
set -e
set -x

# Set the project variables
source $PWD/configurations/test.xcconfig

# Resolve a simulator that exists on this machine (honors TEST_DESTINATION) and
# record it, so test-without-building runs on the device we built products for
DESTINATION=$(bash "$(dirname "$0")/resolve-test-destination.sh" "$DEVICE_NAME")
mkdir -p "$1"
echo "$DESTINATION" >"$1/test-destination"

# xcbeautify only prettifies the log, so run without it when it isn't installed
if command -v xcbeautify >/dev/null 2>&1; then
    FORMATTER=(xcbeautify)
else
    echo "xcbeautify not found, using raw xcodebuild output. Run 'make setup' to install it." 1>&2
    FORMATTER=(cat)
fi

# Build the project
xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -project "$PROJECT" \
    -destination "$DESTINATION" \
    -sdk "$SDK" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$1" |
    "${FORMATTER[@]}"

echo "Process completed successfully."
