#!/bin/bash

# DMG Creation Script for DynamicNotch4Mac
# Creates a professional installer DMG with proper layout

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DynamicNotch4Mac"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="DynamicNotch4Mac-1.0.0"
DMG_TITLE="Dynamic Notch 1.0.0"
DMG_SIZE="100m"  # 100MB should be plenty
TEMP_DMG="temp_${DMG_NAME}.dmg"
FINAL_DMG="${DMG_NAME}.dmg"

echo "📀 Creating DMG installer for ${APP_NAME}..."

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ ${APP_BUNDLE} not found! Please build the app first using build_production.sh"
    exit 1
fi

# Clean up any existing DMG files
echo "🧹 Cleaning up existing DMG files..."
rm -f "${TEMP_DMG}" "${FINAL_DMG}"

# Create temporary DMG
echo "📀 Creating temporary DMG..."
hdiutil create -size "${DMG_SIZE}" -fs HFS+ -volname "${DMG_TITLE}" "${TEMP_DMG}"

# Mount the temporary DMG
echo "🔗 Mounting temporary DMG..."
MOUNT_POINT=$(hdiutil attach "${TEMP_DMG}" | grep "/Volumes/" | cut -d$'\t' -f3)

if [ -z "${MOUNT_POINT}" ]; then
    echo "❌ Failed to mount DMG!"
    exit 1
fi

echo "📁 DMG mounted at: ${MOUNT_POINT}"

# Copy app bundle to DMG
echo "📦 Copying app bundle to DMG..."
cp -R "${APP_BUNDLE}" "${MOUNT_POINT}/"

# Create Applications symlink for easy installation
echo "🔗 Creating Applications symlink..."
ln -s /Applications "${MOUNT_POINT}/Applications"

# Create README file
echo "📝 Creating README..."
cat > "${MOUNT_POINT}/README.txt" << EOF
Dynamic Notch for macOS v1.0.0
==============================

Thank you for downloading Dynamic Notch!

INSTALLATION:
1. Drag "DynamicNotch4Mac.app" to the "Applications" folder
2. Open the app from Applications or Launchpad
3. Grant necessary permissions when prompted:
   - Location access (for weather)
   - Calendar access (for events)
   - Reminders access (for tasks)

USAGE:
- The app runs in the menu bar (look for the display icon)
- Move your mouse to the top center of the screen to activate the dynamic notch
- Drag files to the notch area to use the file tray feature
- Right-click the menu bar icon for settings and options

FEATURES:
• Dynamic notch that shows time, weather, and reminders
• File tray for temporary file storage and management
• Calendar integration for upcoming events
• Customizable display options
• Auto-start on login (optional)

SYSTEM REQUIREMENTS:
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

SUPPORT:
For support and updates, visit: https://github.com/yourusername/dynamicNotch4mac

Enjoy your new dynamic notch experience!
EOF

# Create an installer script in the DMG (optional advanced installation)
echo "🛠️ Creating installer script in DMG..."
cat > "${MOUNT_POINT}/Install DynamicNotch.command" << 'EOF'
#!/bin/bash

echo "🚀 Installing Dynamic Notch..."

# Get the directory where this script is located (the DMG mount point)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="DynamicNotch4Mac.app"
BUNDLE_ID="com.dynamicnotch.app"

# Check if app exists in DMG
if [ ! -d "${SCRIPT_DIR}/${APP_NAME}" ]; then
    echo "❌ ${APP_NAME} not found in DMG!"
    exit 1
fi

# Stop existing app if running
echo "🛑 Stopping existing app if running..."
pkill -f "DynamicNotch4Mac" 2>/dev/null || true

# Remove old installation
echo "🧹 Removing old installation..."
rm -rf "/Applications/${APP_NAME}"

# Install app
echo "📦 Installing ${APP_NAME} to Applications..."
cp -R "${SCRIPT_DIR}/${APP_NAME}" /Applications/

# Set permissions
chmod +x "/Applications/${APP_NAME}/Contents/MacOS/DynamicNotch4Mac"

echo "✅ Installation completed!"
echo "🚀 You can now launch Dynamic Notch from Applications!"

# Ask if user wants to start the app
read -p "Would you like to start Dynamic Notch now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting Dynamic Notch..."
    open "/Applications/${APP_NAME}"
fi

echo "🎉 Installation complete! The app will appear in your menu bar."
EOF

chmod +x "${MOUNT_POINT}/Install DynamicNotch.command"

# Set DMG background and layout (if you have background image)
echo "🎨 Setting up DMG layout..."

# Create .DS_Store for custom layout
# Note: For a more professional look, you'd typically create a custom background image
# and set specific icon positions using AppleScript or similar tools

# Set basic Finder view options
osascript << EOF
tell application "Finder"
    tell disk "${DMG_TITLE}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 800, 500}
        set arrangement of icon view options of container window to not arranged
        set icon size of icon view options of container window to 72
        delay 1
        close
    end tell
end tell
EOF

# Wait for Finder to finish
sleep 2

# Unmount the DMG
echo "⏏️ Unmounting DMG..."
hdiutil detach "${MOUNT_POINT}"

# Convert to final compressed DMG
echo "🗜️ Creating final compressed DMG..."
hdiutil convert "${TEMP_DMG}" -format UDZO -o "${FINAL_DMG}"

# Clean up temporary DMG
rm -f "${TEMP_DMG}"

# Set DMG permissions
chmod 644 "${FINAL_DMG}"

echo "✅ DMG creation completed!"
echo "📍 DMG location: $(pwd)/${FINAL_DMG}"
echo "📊 DMG size: $(du -h "${FINAL_DMG}" | cut -f1)"

# Verify DMG
echo "🔍 Verifying DMG..."
if hdiutil verify "${FINAL_DMG}"; then
    echo "✅ DMG verification successful!"
else
    echo "⚠️ DMG verification failed, but file was created"
fi

echo ""
echo "🎉 DMG installer created successfully!"
echo "📀 File: ${FINAL_DMG}"
echo "💡 You can now distribute this DMG file to users"
echo "📤 Users can mount the DMG and drag the app to Applications"
echo ""
