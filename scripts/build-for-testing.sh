#!/bin/bash

# Set the root directory
export ROOT=$PWD

# Set the project variables
source $ROOT/configurations/test.xcconfig

# Bootstrap the project
source $ROOT/scripts/bootstrap.sh

# # Run XcodeGen to regenerate the project
# echo "Removing existing Xcode project..."
# rm -rf "$PROJECT"

# echo "Generating new Xcode project with XcodeGen..."
# xcodegen

# echo "----------------------------------------------------------------------------------------------------"

# Build the project
echo "Building the iOS project..."
xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -project "$PROJECT" \
    -destination "$DESTANATION" \
    -sdk "$SDK" \
    -configuration "$CONFIGURATION" |
    xcbeautify

echo "Process completed successfully."
