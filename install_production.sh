#!/bin/bash

# Production Installer Script for DynamicNotch4Mac
# This script installs the app and sets up auto-start functionality

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DynamicNotch4Mac"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.dynamicnotch.app"
LAUNCH_AGENT_PLIST="${BUNDLE_ID}.plist"

echo "🚀 Installing ${APP_NAME}..."

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ ${APP_BUNDLE} not found! Please build the app first using build_production.sh"
    exit 1
fi

# Stop existing app if running
echo "🛑 Stopping existing app if running..."
pkill -f "${APP_NAME}" 2>/dev/null || true

# Unload existing launch agent if present
echo "🔄 Unloading existing launch agent..."
launchctl unload ~/Library/LaunchAgents/"${LAUNCH_AGENT_PLIST}" 2>/dev/null || true

# Remove old installation
echo "🧹 Removing old installation..."
rm -rf /Applications/"${APP_BUNDLE}"
rm -f ~/Library/LaunchAgents/"${LAUNCH_AGENT_PLIST}"

# Install app to Applications
echo "📦 Installing app to /Applications..."
cp -R "${APP_BUNDLE}" /Applications/

# Set proper permissions
echo "🔐 Setting permissions..."
chmod +x /Applications/"${APP_BUNDLE}"/Contents/MacOS/"${APP_NAME}"

# Install launch agent for auto-start
echo "🚀 Setting up auto-start..."
if [ -f "${LAUNCH_AGENT_PLIST}" ]; then
    cp "${LAUNCH_AGENT_PLIST}" ~/Library/LaunchAgents/
    chmod 644 ~/Library/LaunchAgents/"${LAUNCH_AGENT_PLIST}"
    
    # Load the launch agent
    launchctl load ~/Library/LaunchAgents/"${LAUNCH_AGENT_PLIST}"
    echo "✅ Auto-start configured successfully!"
else
    echo "⚠️  Launch agent plist not found. Auto-start will not be configured."
fi

# Verify installation
echo "🔍 Verifying installation..."
if [ -d "/Applications/${APP_BUNDLE}" ]; then
    echo "✅ App installed successfully at /Applications/${APP_BUNDLE}"
else
    echo "❌ Installation failed!"
    exit 1
fi

# Check if launch agent is loaded
if launchctl list | grep -q "${BUNDLE_ID}"; then
    echo "✅ Launch agent loaded successfully"
else
    echo "⚠️  Launch agent not loaded (this might be normal)"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📍 App location: /Applications/${APP_BUNDLE}"
echo "🚀 Auto-start: Enabled (launch agent installed)"
echo "💡 The app will start automatically on next login"
echo ""
echo "To manually start the app now:"
echo "   open /Applications/${APP_BUNDLE}"
echo ""
echo "To disable auto-start:"
echo "   launchctl unload ~/Library/LaunchAgents/${LAUNCH_AGENT_PLIST}"
echo ""
echo "To enable auto-start again:"
echo "   launchctl load ~/Library/LaunchAgents/${LAUNCH_AGENT_PLIST}"
echo ""

# Offer to start the app now
read -p "Would you like to start the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting ${APP_NAME}..."
    open /Applications/"${APP_BUNDLE}"
    echo "✅ ${APP_NAME} started!"
fi

echo "🎊 Installation complete! Enjoy using ${APP_NAME}!"
