# 🌟 DynamicNotch4Mac

Transform your Mac with a **dynamic notch** that shows time, weather, reminders, and more! Perfect for MacBook users who want the iPhone's Dynamic Island experience on their Mac.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-Open%20Source-green)
![Downloads](https://img.shields.io/github/downloads/yourusername/dynamicNotch4mac/total)

**🚀 [Download Latest Release](https://github.com/yourusername/dynamicNotch4mac/releases/latest) | 📖 [Installation Guide](INSTALL.md) | 🤝 [Contributing](CONTRIBUTING.md)**

## Features

### 🌟 Dynamic Notch Display
- **Time & Date**: Always-visible current time and date
- **Weather Information**: Live weather updates based on your location
- **Reminders Integration**: Shows your active reminders from the Reminders app
- **Calendar Events**: Displays upcoming events from the next 3 hours
- **Smart Content Switching**: Automatically adapts based on context

### 📁 File Tray Management
- **Drag & Drop Support**: Drag files to the notch area for temporary storage
- **Visual File Preview**: Quick file type identification with icons
- **Batch Operations**: Handle multiple files simultaneously
- **Cross-Application Support**: Works with Finder, desktop, and other apps

### ⚙️ Customization Options
- **Toggle Components**: Enable/disable time, weather, reminders, or file count
- **Auto-Start**: Optional automatic startup with macOS
- **Menu Bar Integration**: Convenient access through menu bar icon
- **Permissions Management**: Guided setup for calendar, reminders, and location access

## System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Universal (Apple Silicon + Intel)
- **Permissions**: Location (for weather), Calendar, Reminders (optional but recommended)

## 📥 Installation

### For Regular Users (Easy!)
**👉 See the [Installation Guide](INSTALL.md) for step-by-step instructions with screenshots**

**Quick Summary:**
1. **Download** `DynamicNotch4Mac-1.0.0.dmg` from [Releases](https://github.com/yourusername/dynamicNotch4mac/releases)
2. **Open** the DMG and drag the app to Applications
3. **Launch** and grant permissions when prompted
4. **Enjoy** your dynamic notch!

### For Developers
```bash
git clone https://github.com/yourusername/dynamicNotch4mac.git
cd dynamicNotch4mac
./build_release.sh
```

## 🎮 How to Use

### First Time Setup
1. **Grant Permissions**: Allow access to Location, Calendar, and Reminders when prompted
2. **Find the Menu Bar Icon**: Look for the display icon in your menu bar
3. **Activate the Notch**: Move your mouse to the top-center of your screen

### Daily Usage
- **📊 View Information**: The notch shows time, weather, reminders, and calendar events
- **📁 File Management**: Drag files to the notch to use the file tray feature
- **⚙️ Settings**: Left-click the menu bar icon to customize what's displayed
- **🚀 Auto-Hide**: The notch disappears when you move your mouse away

### Pro Tips
- Use the file tray to temporarily store files while working
- Check upcoming events without opening Calendar
- Quickly see how many active reminders you have
- Customize which information is displayed in settings

## 🛠 For Developers

### Building from Source
**📋 See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development setup**

```bash
# Quick development build
./build_production.sh

# Full release build with DMG
./build_release.sh

# Code signing (requires certificates)
./codesign_and_notarize.sh
```

### Build Scripts
| Script | Purpose |
|--------|---------|
| `build_production.sh` | Build app bundle |
| `build_release.sh` | Complete build + DMG |
| `create_dmg.sh` | Create installer DMG |
| `install_production.sh` | Local installation |

## Project Structure

```
DynamicNotch4Mac/
├── Sources/
│   ├── App.swift              # Main app entry point
│   ├── AppDelegate.swift      # Core app logic and notch management
│   └── ContentView.swift      # SwiftUI interface components
├── Scripts/
│   ├── build_production.sh    # Production build script
│   ├── build_release.sh       # Master release build script
│   ├── create_dmg.sh          # DMG creation script
│   ├── install_production.sh  # Automated installer
│   └── codesign_and_notarize.sh # Code signing and notarization
├── DynamicNotch4Mac.app/      # Built application bundle
├── Package.swift              # Swift Package Manager configuration
└── README.md                  # This file
```

## Architecture

### Key Components

- **AppDelegate**: Central coordinator handling notch display, permissions, and data management
- **DynamicContentView**: SwiftUI interface with tabbed navigation
- **Error Handling**: Comprehensive error management with user-friendly alerts
- **Logging**: Structured logging using os.log for debugging and monitoring
- **Permissions**: Robust permission handling for all required system access

### Dependencies

- **DynamicNotchKit**: Core notch functionality
- **EventKit**: Calendar and reminders integration
- **CoreLocation**: Location services for weather data
- **SwiftUI & AppKit**: Modern UI framework with native macOS integration

## Development

### Architecture Decisions
- **SwiftUI + AppKit**: Hybrid approach for modern UI with platform-specific features
- **ObservableObject**: Reactive data flow between AppDelegate and views
- **Structured Logging**: Production-ready logging with multiple log levels
- **Error-First Design**: Comprehensive error handling throughout the application

### Code Quality
- **Memory Management**: Proper cleanup of timers and observers
- **Thread Safety**: Main thread enforcement for UI updates
- **Performance**: Optimized for minimal system resource usage
- **Accessibility**: VoiceOver support and keyboard navigation

## Production Deployment

### Code Signing
1. Configure your Developer ID certificate in `codesign_and_notarize.sh`
2. Set up notarization credentials for App Store distribution
3. Run the signing script before distribution

### Distribution Checklist
- [ ] Code signed with valid Developer ID
- [ ] Notarized by Apple (for public distribution)
- [ ] DMG tested on clean system
- [ ] All permissions working correctly
- [ ] Auto-start functionality verified
- [ ] Menu bar integration tested

## Troubleshooting

### Common Issues

**App won't start**
- Check macOS version (requires 13.0+)
- Verify app permissions in System Settings
- Try running from Terminal to see error messages

**Notch not appearing**
- Ensure you're moving mouse to top-center of screen
- Check that the app is running (menu bar icon should be visible)
- Try restarting the app

**Permissions not working**
- Open System Settings > Privacy & Security
- Grant permissions for Calendar, Reminders, and Location Services
- Restart the app after granting permissions

**Weather not updating**
- Verify location permissions are granted
- Check internet connectivity
- Location services must be enabled system-wide

### Debug Mode
For development debugging:
```bash
# View logs
log stream --predicate 'subsystem == "com.dynamicnotch.app"'

# Check permissions
tccutil list com.dynamicnotch.app
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Update documentation as needed
5. Submit a pull request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Include comprehensive error handling
- Add logging for significant operations

## License

© 2024 DynamicNotch4Mac. All rights reserved.

## Support

For support, bug reports, or feature requests:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review system requirements and permissions

## Changelog

### Version 1.0.0
- Initial release
- Dynamic notch with time, weather, and reminders
- File tray functionality with drag & drop
- Calendar integration
- Auto-start capability
- Production-ready build system
- Comprehensive error handling and logging