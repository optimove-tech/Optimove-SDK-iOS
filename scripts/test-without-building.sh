#!/bin/bash

# Set the root directory
export ROOT=$PWD

# Set the project variables
source $ROOT/configurations/test.xcconfig

# Bootstrap the project
source $ROOT/scripts/bootstrap.sh

# Run the tests
xcodebuild test-without-building \
    -scheme "$SCHEME" \
    -project "$PROJECT" \
    -destination "$DESTANATION" \
    -sdk "$SDK" \
    -configuration "$CONFIGURATION" |
    xcbeautify

echo "Process completed successfully."
