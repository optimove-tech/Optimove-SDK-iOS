#!/bin/bash

# Stop the script if any command fails
set -e

# Check if xcodebuild is installed
if ! command -v xcodebuild &>/dev/null; then
    echo "xcodebuild is not installed. Please install Xcode from the App Store or update your PATH."
    exit 1
fi

# Check if XcodeGen is installed, if not, attempt to install it
if ! command -v xcodegen &>/dev/null; then
    echo "XcodeGen is not installed. Attempting to install using Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew is not installed. Cannot install XcodeGen."
        exit 1
    fi
    brew install xcodegen
fi

# Check if xcbeautify is installed, if not, attempt to install it
if ! command -v xcbeautify &>/dev/null; then
    echo "xcbeautify is not installed. Attempting to install using Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew is not installed. Cannot install xcbeautify."
        exit 1
    fi
    brew install xcbeautify
fi

# Define your scheme and workspace/project name
SCHEME="UnitTests"
PROJECT="Optimove.xcodeproj"
SDK="iphonesimulator"
DESTANATION="platform=iOS Simulator,name=iPhone 15"
CONFIGURATION="Debug"

# TODO: Move lines above to xconfig file

# Print the info
echo "Starting process..."
echo "----------------------------------------------------------------------------------------------------"
echo "Project: $PROJECT"
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "SDK: $SDK"
echo "Destination: $DESTANATION"
echo "----------------------------------------------------------------------------------------------------"

# Run XcodeGen to regenerate the project
echo "Removing existing Xcode project..."
rm -rf "$PROJECT"
echo "Generating new Xcode project with XcodeGen..."
xcodegen

echo "----------------------------------------------------------------------------------------------------"

# Function to run xcodebuild and xcbeautify
run_xcodebuild() {
    echo "Running xcodebuild command: $*"
    xcodebuild "$@" | xcbeautify
    echo "----------------------------------------------------------------------------------------------------"
}

# Build the project
echo "Building the iOS project..."
run_xcodebuild build-for-testing -scheme "$SCHEME" -project "$PROJECT" \
    -destination "$DESTANATION" -sdk "$SDK" -configuration "$CONFIGURATION"

echo "Process completed successfully."
