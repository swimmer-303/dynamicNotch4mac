#!/bin/bash

# Code Signing and Notarization Script for DynamicNotch4Mac
# This script handles code signing and notarization for distribution

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DynamicNotch4Mac"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.dynamicnotch.app"
DMG_NAME="DynamicNotch4Mac-1.0.0.dmg"

# Configuration (you'll need to set these)
DEVELOPER_ID_CERT=""  # e.g., "Developer ID Application: Your Name (XXXXXXXXXX)"
DEVELOPER_ID_INSTALLER=""  # e.g., "Developer ID Installer: Your Name (XXXXXXXXXX)"
APPLE_ID=""  # Your Apple ID email
APP_SPECIFIC_PASSWORD=""  # App-specific password for notarization
TEAM_ID=""  # Your Apple Developer Team ID

echo "🔐 Code Signing and Notarization for ${APP_NAME}"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ ${APP_BUNDLE} not found! Please build the app first."
    exit 1
fi

# Check if certificates are installed
if [ -z "$DEVELOPER_ID_CERT" ]; then
    echo "⚠️  Developer ID Application certificate not specified."
    echo "Please edit this script and set DEVELOPER_ID_CERT to your certificate name."
    echo ""
    echo "Available certificates:"
    security find-identity -v -p codesigning
    echo ""
    echo "Example: DEVELOPER_ID_CERT=\"Developer ID Application: Your Name (XXXXXXXXXX)\""
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID_CERT"; then
    echo "❌ Certificate '$DEVELOPER_ID_CERT' not found!"
    echo "Available certificates:"
    security find-identity -v -p codesigning
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create entitlements file
echo "📝 Creating entitlements..."
cat > entitlements.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <false/>
    
    <!-- Required capabilities -->
    <key>com.apple.security.device.audio-input</key>
    <false/>
    <key>com.apple.security.device.camera</key>
    <false/>
    <key>com.apple.security.personal-information.location</key>
    <true/>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Network access -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
EOF

# Sign all binaries and frameworks first
echo "🖊️  Signing frameworks and libraries..."
find "${APP_BUNDLE}" -type f \( -name "*.dylib" -o -name "*.framework" \) -exec codesign --force --verify --verbose --timestamp --options runtime --entitlements entitlements.plist --sign "$DEVELOPER_ID_CERT" {} \;

# Sign the main executable
echo "🖊️  Signing main executable..."
codesign --force --verify --verbose --timestamp --options runtime --entitlements entitlements.plist --sign "$DEVELOPER_ID_CERT" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Sign the entire app bundle
echo "🖊️  Signing app bundle..."
codesign --force --verify --verbose --timestamp --options runtime --entitlements entitlements.plist --sign "$DEVELOPER_ID_CERT" "${APP_BUNDLE}"

# Verify signing
echo "✅ Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"
spctl --assess --type execute --verbose "${APP_BUNDLE}"

echo "✅ Code signing completed successfully!"

# Check if notarization is requested
if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
    echo ""
    echo "📤 Starting notarization process..."
    
    # Create a ZIP archive for notarization
    ARCHIVE_NAME="${APP_NAME}-for-notarization.zip"
    echo "📦 Creating ZIP archive for notarization..."
    ditto -c -k --keepParent "${APP_BUNDLE}" "${ARCHIVE_NAME}"
    
    # Submit for notarization
    echo "📤 Submitting to Apple for notarization..."
    NOTARIZATION_RESPONSE=$(xcrun notarytool submit "${ARCHIVE_NAME}" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait)
    
    echo "$NOTARIZATION_RESPONSE"
    
    # Check if notarization was successful
    if echo "$NOTARIZATION_RESPONSE" | grep -q "status: Accepted"; then
        echo "✅ Notarization successful!"
        
        # Staple the notarization to the app
        echo "📎 Stapling notarization ticket..."
        xcrun stapler staple "${APP_BUNDLE}"
        
        # Verify stapling
        echo "✅ Verifying stapled notarization..."
        xcrun stapler validate "${APP_BUNDLE}"
        
        echo "✅ App is now notarized and ready for distribution!"
        
        # Clean up
        rm -f "${ARCHIVE_NAME}"
        
    else
        echo "❌ Notarization failed!"
        echo "Check the response above for details."
        
        # Get detailed log if submission ID is available
        if echo "$NOTARIZATION_RESPONSE" | grep -q "id:"; then
            SUBMISSION_ID=$(echo "$NOTARIZATION_RESPONSE" | grep "id:" | awk '{print $2}')
            echo "📄 Getting detailed notarization log..."
            xcrun notarytool log "$SUBMISSION_ID" \
                --apple-id "$APPLE_ID" \
                --password "$APP_SPECIFIC_PASSWORD" \
                --team-id "$TEAM_ID"
        fi
        
        exit 1
    fi
else
    echo ""
    echo "⚠️  Notarization skipped - missing credentials"
    echo "To enable notarization, set these variables in the script:"
    echo "  APPLE_ID=\"your-apple-id@example.com\""
    echo "  APP_SPECIFIC_PASSWORD=\"your-app-specific-password\""
    echo "  TEAM_ID=\"your-team-id\""
    echo ""
    echo "✅ Code signing completed. App is signed but not notarized."
fi

# Sign DMG if it exists
if [ -f "$DMG_NAME" ]; then
    echo ""
    echo "🖊️  Signing DMG..."
    codesign --force --verify --verbose --timestamp --sign "$DEVELOPER_ID_CERT" "$DMG_NAME"
    echo "✅ DMG signed successfully!"
fi

# Clean up
rm -f entitlements.plist

echo ""
echo "🎉 Code signing process completed!"
echo "📍 Signed app: ${APP_BUNDLE}"
if [ -f "$DMG_NAME" ]; then
    echo "📍 Signed DMG: ${DMG_NAME}"
fi
echo ""
echo "💡 Your app is now ready for distribution!"

# Final verification
echo "🔍 Final verification..."
echo "App signature:"
codesign -dv --verbose=4 "${APP_BUNDLE}" 2>&1 | head -10

echo ""
echo "Gatekeeper assessment:"
spctl --assess --type execute --verbose "${APP_BUNDLE}"

echo ""
echo "✅ All done! Your app is production-ready."
