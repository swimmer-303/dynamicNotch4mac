#!/bin/bash

# Master Release Build Script for DynamicNotch4Mac
# This script builds, signs, and creates a distributable DMG

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DynamicNotch4Mac"
VERSION="1.0.0"

echo "🚀 Building ${APP_NAME} v${VERSION} for release distribution"
echo "=============================================================="

# Step 1: Clean previous builds
echo ""
echo "🧹 Step 1: Cleaning previous builds..."
rm -rf .build
rm -rf "${APP_NAME}.app"
rm -f "${APP_NAME}-${VERSION}.dmg"
rm -f "${APP_NAME}-for-notarization.zip"
echo "✅ Cleanup completed"

# Step 2: Build the app
echo ""
echo "🔨 Step 2: Building app bundle..."
if ! ./build_production.sh; then
    echo "❌ App build failed!"
    exit 1
fi
echo "✅ App build completed"

# Step 3: Code signing (optional - requires certificates)
echo ""
echo "🔐 Step 3: Code signing..."
if [ -f "codesign_and_notarize.sh" ]; then
    read -p "Do you want to code sign the app? (requires Developer ID certificate) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! ./codesign_and_notarize.sh; then
            echo "⚠️  Code signing failed, continuing without signing..."
        else
            echo "✅ Code signing completed"
        fi
    else
        echo "⏭️  Skipping code signing"
    fi
else
    echo "⏭️  Code signing script not found, skipping"
fi

# Step 4: Create DMG
echo ""
echo "📀 Step 4: Creating DMG installer..."
if ! ./create_dmg.sh; then
    echo "❌ DMG creation failed!"
    exit 1
fi
echo "✅ DMG creation completed"

# Step 5: Final verification
echo ""
echo "🔍 Step 5: Final verification..."

APP_BUNDLE="${APP_NAME}.app"
DMG_FILE="${APP_NAME}-${VERSION}.dmg"

if [ -d "$APP_BUNDLE" ]; then
    echo "✅ App bundle exists: $APP_BUNDLE"
    echo "📊 App bundle size: $(du -sh "$APP_BUNDLE" | cut -f1)"
    
    # Check if app is signed
    if codesign -dv "$APP_BUNDLE" 2>/dev/null; then
        echo "✅ App is code signed"
    else
        echo "⚠️  App is not code signed"
    fi
    
    # Check executable
    if [ -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]; then
        echo "✅ Executable is present and executable"
    else
        echo "❌ Executable is missing or not executable"
    fi
    
    # Check Info.plist
    if [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
        echo "✅ Info.plist is present"
        BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "Unknown")
        echo "📋 Bundle version: $BUNDLE_VERSION"
    else
        echo "❌ Info.plist is missing"
    fi
else
    echo "❌ App bundle not found!"
    exit 1
fi

if [ -f "$DMG_FILE" ]; then
    echo "✅ DMG file exists: $DMG_FILE"
    echo "📊 DMG size: $(du -sh "$DMG_FILE" | cut -f1)"
    
    # Verify DMG
    if hdiutil verify "$DMG_FILE" >/dev/null 2>&1; then
        echo "✅ DMG verification passed"
    else
        echo "⚠️  DMG verification failed"
    fi
else
    echo "❌ DMG file not found!"
    exit 1
fi

# Step 6: Generate distribution summary
echo ""
echo "📋 Step 6: Distribution summary"
echo "=============================="

cat > "DISTRIBUTION_${VERSION}.md" << EOF
# DynamicNotch4Mac v${VERSION} - Distribution Package

Generated on: $(date)

## Files in this release:

### App Bundle
- **File**: \`${APP_BUNDLE}\`
- **Size**: $(du -sh "$APP_BUNDLE" 2>/dev/null | cut -f1 || echo "Unknown")
- **Signed**: $(codesign -dv "$APP_BUNDLE" 2>/dev/null && echo "Yes" || echo "No")

### DMG Installer
- **File**: \`${DMG_FILE}\`
- **Size**: $(du -sh "$DMG_FILE" 2>/dev/null | cut -f1 || echo "Unknown")
- **Verified**: $(hdiutil verify "$DMG_FILE" >/dev/null 2>&1 && echo "Yes" || echo "No")

## Installation Instructions

### For End Users (Recommended):
1. Download and open \`${DMG_FILE}\`
2. Drag \`DynamicNotch4Mac.app\` to the Applications folder
3. Launch the app from Applications or Launchpad
4. Grant necessary permissions when prompted

### For Developers:
1. Use \`install_production.sh\` for automated installation with auto-start setup
2. Use individual build scripts for development

## System Requirements
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Features
- Dynamic notch display with time, weather, and reminders
- File tray for drag-and-drop file management
- Calendar integration for upcoming events
- Customizable display options
- Auto-start capability
- Menu bar integration

## Technical Details
- Bundle ID: com.dynamicnotch.app
- Version: ${VERSION}
- Build: $(date +%Y%m%d)
- Architecture: Universal (ARM64 + x86_64)

---
Built with ❤️ using Swift and DynamicNotchKit
EOF

echo "✅ Distribution summary created: DISTRIBUTION_${VERSION}.md"

# Final success message
echo ""
echo "🎉 Release build completed successfully!"
echo "======================================"
echo ""
echo "📦 Deliverables:"
echo "  • App Bundle: ${APP_BUNDLE}"
echo "  • DMG Installer: ${DMG_FILE}"
echo "  • Distribution Notes: DISTRIBUTION_${VERSION}.md"
echo ""
echo "📤 Ready for distribution!"
echo ""
echo "💡 Next steps:"
echo "  1. Test the app on a clean system"
echo "  2. Test the DMG installer"
echo "  3. Distribute to users"
echo ""
echo "🔗 Quick test commands:"
echo "  • Test app: open '${APP_BUNDLE}'"
echo "  • Test DMG: open '${DMG_FILE}'"
echo ""

# Ask if user wants to test now
read -p "Would you like to test the app now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Launching ${APP_NAME}..."
    open "$APP_BUNDLE"
fi

echo "✨ Build process complete!"
