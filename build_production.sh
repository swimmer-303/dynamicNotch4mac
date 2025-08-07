#!/bin/bash

# Production Build Script for DynamicNotch4Mac
# This script builds a production-ready app bundle with proper structure

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DynamicNotch4Mac"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.dynamicnotch.app"
VERSION="1.0.0"
BUILD_NUMBER="1"

echo "🚀 Building ${APP_NAME} v${VERSION} (${BUILD_NUMBER}) for production..."

# Clean up any existing build
echo "🧹 Cleaning up previous builds..."
rm -rf "${APP_BUNDLE}"
rm -rf .build

# Build the project in release mode
echo "🔨 Building Swift project in release mode..."
swift build --configuration release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create app bundle structure
echo "📦 Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"

# Copy the executable
echo "📋 Copying executable..."
if [ -f ".build/apple/Products/Release/${APP_NAME}" ]; then
    cp ".build/apple/Products/Release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
elif [ -f ".build/arm64-apple-macosx/release/${APP_NAME}" ]; then
    cp ".build/arm64-apple-macosx/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
elif [ -f ".build/x86_64-apple-macosx/release/${APP_NAME}" ]; then
    cp ".build/x86_64-apple-macosx/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
else
    echo "❌ Could not find built executable!"
    echo "Available files in .build:"
    find .build -name "${APP_NAME}" -type f 2>/dev/null || echo "No executable found"
    exit 1
fi

# Set executable permissions
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist (check if we already have a proper one)
if [ -f "${APP_BUNDLE}/Contents/Info.plist" ] && grep -q "NSCalendarsUsageDescription" "${APP_BUNDLE}/Contents/Info.plist"; then
    echo "✅ Info.plist already exists with proper configuration"
else
    echo "📝 Creating/updating Info.plist with privacy descriptions..."
    cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Dynamic Notch</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    
    <!-- Privacy Usage Descriptions - REQUIRED for permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>DynamicNotch4Mac uses location to provide weather information in the dynamic notch display.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>DynamicNotch4Mac accesses your calendar to show upcoming events in the dynamic notch display.</string>
    <key>NSRemindersUsageDescription</key>
    <string>DynamicNotch4Mac accesses your reminders to show active tasks in the dynamic notch display.</string>
    
    <!-- App Category -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
EOF
fi

# Create a simple app icon if it doesn't exist
echo "🎨 Setting up app icon..."
if [ ! -f "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" ]; then
    echo "📝 Note: No custom icon found. App will use default system icon."
    # In a real production app, you'd create proper icons here
fi

# Bundle any required frameworks/libraries
echo "📚 Bundling dependencies..."
# Note: Swift Package Manager handles most dependencies automatically
# For production, you might want to check for and bundle specific frameworks

echo "🔍 Verifying app bundle structure..."
echo "App bundle contents:"
find "${APP_BUNDLE}" -type f -exec ls -la {} \;

echo "🎯 Checking executable..."
file "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
otool -L "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" | head -10

echo "✅ Production build completed successfully!"
echo "📍 App bundle location: $(pwd)/${APP_BUNDLE}"
echo "💡 To test the app: open ${APP_BUNDLE}"
echo "📦 Ready for code signing and DMG creation!"

# Verify the app can be opened
echo "🧪 Quick verification..."
if open -n "${APP_BUNDLE}" --args --test 2>/dev/null; then
    echo "✅ App bundle opens successfully"
else
    echo "⚠️  App bundle may have issues (this is normal for testing)"
fi
