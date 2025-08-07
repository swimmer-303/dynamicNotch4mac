#!/bin/bash

# Create Release Script for DynamicNotch4Mac
# This script builds the app and creates a release-ready DMG for distribution

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="1.0.0"
APP_NAME="DynamicNotch4Mac"
DMG_NAME="${APP_NAME}-${VERSION}"

echo "🚀 Creating Release v${VERSION}"
echo "================================"

# Step 1: Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf "${APP_NAME}.app"
rm -f "${DMG_NAME}.dmg"
echo "✅ Cleanup completed"

# Step 2: Build the app
echo ""
echo "🔨 Building production app..."
if ! ./build_production.sh; then
    echo "❌ Build failed!"
    exit 1
fi

# Step 3: Create DMG
echo ""
echo "📀 Creating release DMG..."
if ! ./create_dmg.sh; then
    echo "❌ DMG creation failed!"
    exit 1
fi

# Step 4: Verify release
echo ""
echo "🔍 Verifying release..."

if [ ! -f "${DMG_NAME}.dmg" ]; then
    echo "❌ DMG file not found!"
    exit 1
fi

# Check DMG
echo "📊 DMG size: $(du -sh "${DMG_NAME}.dmg" | cut -f1)"

# Verify DMG integrity
if hdiutil verify "${DMG_NAME}.dmg" >/dev/null 2>&1; then
    echo "✅ DMG verification passed"
else
    echo "⚠️ DMG verification failed"
fi

# Step 5: Release summary
echo ""
echo "🎉 Release v${VERSION} Ready!"
echo "=========================="
echo ""
echo "📦 Release Files:"
echo "  • ${DMG_NAME}.dmg"
echo ""
echo "📋 Upload Instructions:"
echo "1. Go to GitHub > Releases > Draft a new release"
echo "2. Tag: v${VERSION}"
echo "3. Title: DynamicNotch4Mac v${VERSION}"
echo "4. Upload: ${DMG_NAME}.dmg"
echo "5. Copy release notes from RELEASE_NOTES.md"
echo ""
echo "🔗 After Release:"
echo "1. Update download links in README.md"
echo "2. Test download and installation"
echo "3. Announce on social media!"
echo ""

# Ask if user wants to open the DMG for testing
read -p "Would you like to test the DMG now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧪 Opening DMG for testing..."
    open "${DMG_NAME}.dmg"
fi

echo "✨ Release creation complete!"
