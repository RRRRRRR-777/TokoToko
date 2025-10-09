#!/bin/sh
# ci_pre_xcodebuild.sh
# XcodeCloud Pre-action script for XcodeGen project generation

set -e
set -x

echo "🚀 Starting XcodeCloud Pre-action script..."

# Change to the project root directory
cd /Volumes/workspace/repository

# Generate GoogleService-Info.plist from environment variable
echo "🔧 Generating GoogleService-Info.plist from environment variable..."

# Check if GOOGLE_SERVICE_INFO_PLIST environment variable is set
if [ -z "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "❌ Error: GOOGLE_SERVICE_INFO_PLIST environment variable is not set"
    exit 1
fi

# Create GoogleService-Info.plist from environment variable
echo "$GOOGLE_SERVICE_INFO_PLIST" > TekuToko/GoogleService-Info.plist

# Verify the file was created
if [ -f TekuToko/GoogleService-Info.plist ]; then
    echo "✅ Successfully generated GoogleService-Info.plist"
    echo "📋 GoogleService-Info.plist file size: $(wc -c < TekuToko/GoogleService-Info.plist) bytes"

    # Validate plist file format
    if /usr/libexec/PlistBuddy -c "Print CLIENT_ID" TekuToko/GoogleService-Info.plist > /dev/null 2>&1; then
        CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print CLIENT_ID" TekuToko/GoogleService-Info.plist)
        echo "📋 CLIENT_ID found: ${CLIENT_ID:0:20}..."
    else
        echo "⚠️  Warning: CLIENT_ID not found in GoogleService-Info.plist"
    fi

    # Validate plist XML format
    if plutil -lint TekuToko/GoogleService-Info.plist > /dev/null 2>&1; then
        echo "✅ GoogleService-Info.plist format is valid"
    else
        echo "❌ Error: GoogleService-Info.plist is not a valid plist file"
        exit 1
    fi
else
    echo "❌ Error: Failed to generate GoogleService-Info.plist"
    exit 1
fi

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing xcodegen via Homebrew..."

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for CI environment
        export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
        echo 'export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"' >> ~/.bash_profile
        source ~/.bash_profile
    fi

    # Install xcodegen
    brew install xcodegen
else
    echo "✅ xcodegen is already installed"
fi

# Verify xcodegen installation
xcodegen --version

# Environment variables are provided by XcodeCloud
echo "📁 Using XcodeCloud environment variables..."

# Check if project.yml exists
if [ ! -f project.yml ]; then
    echo "❌ Error: project.yml not found in current directory"
    exit 1
fi

echo "⚙️  Generating Xcode project using XcodeGen..."

# Generate the Xcode project
xcodegen generate

# Verify the project was generated
if [ ! -f TekuToko.xcodeproj/project.pbxproj ]; then
    echo "❌ Error: Failed to generate TekuToko.xcodeproj"
    exit 1
fi

echo "✅ Successfully generated TekuToko.xcodeproj"
echo "📋 Project contents:"
ls -la TekuToko.xcodeproj/

echo "🎉 Pre-action script completed successfully!"
