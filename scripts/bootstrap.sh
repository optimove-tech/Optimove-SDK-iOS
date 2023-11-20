#!/bin/bash

# Stop the script if any command fails
set -e -o pipefail

echo "Checking dependencies..."

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

echo "Dependencies are installed."

# Print the info
echo "----------------------------------------------------------------------------------------------------"
echo "Project: $PROJECT"
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "SDK: $SDK"
echo "Destination: $DESTANATION"
echo "----------------------------------------------------------------------------------------------------"
