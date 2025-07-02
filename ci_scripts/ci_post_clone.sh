#!/bin/sh
# ci_pre_xcodebuild.sh
# XcodeCloud Pre-action script for XcodeGen project generation

set -e
set -x

echo "🚀 Starting XcodeCloud Pre-action script..."

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

# Load environment variables from .env file
if [ -f .env ]; then
    echo "📁 Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  Warning: .env file not found, using default values"
fi

# Check if project.yml exists
if [ ! -f project.yml ]; then
    echo "❌ Error: project.yml not found in current directory"
    exit 1
fi

echo "⚙️  Generating Xcode project using XcodeGen..."

# Generate the Xcode project
xcodegen generate

# Verify the project was generated
if [ ! -f TokoToko.xcodeproj/project.pbxproj ]; then
    echo "❌ Error: Failed to generate TokoToko.xcodeproj"
    exit 1
fi

echo "✅ Successfully generated TokoToko.xcodeproj"
echo "📋 Project contents:"
ls -la TokoToko.xcodeproj/

echo "🎉 Pre-action script completed successfully!"
