#!/bin/bash

echo "Building DynamicNotch4Mac app bundle..."

# Clean up any existing app bundle
rm -rf DynamicNotch4Mac.app

# Build the project
swift build --configuration release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create app bundle structure
mkdir -p DynamicNotch4Mac.app/Contents/MacOS
mkdir -p DynamicNotch4Mac.app/Contents/Resources

# Copy the executable
cp .build/arm64-apple-macosx/release/DynamicNotch4Mac DynamicNotch4Mac.app/Contents/MacOS/

# Create Info.plist
cat > DynamicNotch4Mac.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Dynamic Notch</string>
    <key>CFBundleExecutable</key>
    <string>DynamicNotch4Mac</string>
    <key>CFBundleIdentifier</key>
    <string>com.dynamicnotch.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DynamicNotch4Mac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "App bundle created successfully!"
echo "Location: $(pwd)/DynamicNotch4Mac.app"