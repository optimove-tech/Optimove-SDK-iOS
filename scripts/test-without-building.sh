#!/bin/bash

set -o pipefail
set -e
set -x

# Set the project variables
source $PWD/configurations/test.xcconfig

# Reuse the destination build-for-testing resolved. Resolving independently can
# pick a different device, because xcodebuild adds simulator clones for parallel
# testing while it runs, and there would be no built products for that device.
if [ -n "$TEST_DESTINATION" ]; then
    DESTINATION="$TEST_DESTINATION"
elif [ -f "$1/test-destination" ]; then
    DESTINATION=$(cat "$1/test-destination")
else
    DESTINATION=$(bash "$(dirname "$0")/resolve-test-destination.sh" "$DEVICE_NAME")
fi

# xcbeautify only prettifies the log, so run without it when it isn't installed
if command -v xcbeautify >/dev/null 2>&1; then
    FORMATTER=(xcbeautify)
else
    echo "xcbeautify not found, using raw xcodebuild output. Run 'make setup' to install it." 1>&2
    FORMATTER=(cat)
fi

# Test the project
xcodebuild test-without-building \
    -scheme "$SCHEME" \
    -project "$PROJECT" \
    -destination "$DESTINATION" \
    -sdk "$SDK" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath $1 |
    "${FORMATTER[@]}"

echo "Process completed successfully."
