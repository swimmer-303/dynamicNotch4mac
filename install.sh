#!/bin/bash

echo "Building DynamicNotch4Mac..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "Build successful! Creating app bundle..."
    
    # Create app bundle structure
    mkdir -p DynamicNotch4Mac.app/Contents/MacOS
    
    # Copy the executable
    cp .build/release/DynamicNotch4Mac DynamicNotch4Mac.app/Contents/MacOS/
    
    # Create Info.plist
    cat > DynamicNotch4Mac.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>DynamicNotch4Mac</string>
	<key>CFBundleIdentifier</key>
	<string>com.example.DynamicNotch4Mac</string>
	<key>CFBundleName</key>
	<string>DynamicNotch4Mac</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
</dict>
</plist>
EOF
    
    # Set executable permissions
    chmod +x DynamicNotch4Mac.app/Contents/MacOS/DynamicNotch4Mac
    
    # Copy to Applications
    echo "Installing to /Applications..."
    cp -R DynamicNotch4Mac.app /Applications/
    
    # Set permissions
    chmod +x /Applications/DynamicNotch4Mac.app/Contents/MacOS/DynamicNotch4Mac
    
    echo "Installation complete! DynamicNotch4Mac is now available in your Applications folder."
    echo "You can launch it from Applications or use: open /Applications/DynamicNotch4Mac.app"
    
else
    echo "Build failed!"
    exit 1
fi 