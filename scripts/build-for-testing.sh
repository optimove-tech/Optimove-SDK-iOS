#!/bin/bash

set -o pipefail
set -e
set -x

# Set the project variables
source $PWD/configurations/test.xcconfig

# Build the project
xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -project "$PROJECT" \
    -destination "$DESTANATION" \
    -sdk "$SDK" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath $1 |
    xcbeautify

echo "Process completed successfully."
