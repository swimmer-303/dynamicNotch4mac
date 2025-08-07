# 🚀 How to Install DynamicNotch4Mac

## Quick Installation (For Everyone)

### Method 1: Download & Install (Easiest)
1. **Download** the latest `DynamicNotch4Mac-1.0.0.dmg` from the [Releases page](https://github.com/yourusername/dynamicNotch4mac/releases)
2. **Open** the downloaded DMG file
3. **Drag** `DynamicNotch4Mac.app` to your Applications folder
4. **Launch** the app from Applications or Launchpad
5. **Grant permissions** when prompted (Location, Calendar, Reminders)

### Method 2: One-Click Installer
1. Download the project
2. Open Terminal in the project folder
3. Run: `./install_production.sh`
4. Follow the prompts

## First Time Setup

### 1. Grant Permissions
When you first run the app, macOS will ask for permissions:

- **📍 Location Services**: For weather information
  - Click "OK" to allow location access
  
- **📅 Calendar Access**: For upcoming events  
  - Click "Allow" to show your events in the notch
  
- **📝 Reminders Access**: For active tasks
  - Click "Allow" to display your reminders

### 2. Find the App
- Look for the **display icon** in your menu bar (top-right of screen)
- Left-click the icon to open settings
- Right-click the icon for quick options

### 3. Using the Dynamic Notch
- **Activate**: Move your mouse to the **top-center** of your screen
- **Browse**: Click through different tabs (Home, Reminders, Calendar, File Tray)
- **File Management**: Drag files to the notch area to use the file tray
- **Hide**: Move mouse away to hide the notch

## Troubleshooting

### App Won't Start?
- Make sure you're running **macOS 13.0 (Ventura) or later**
- Try right-clicking the app and select "Open" (for security)
- Check System Settings > Privacy & Security if blocked

### Notch Not Appearing?
- Ensure the **menu bar icon** is visible (app is running)
- Move mouse to the **very top-center** of your screen
- Try restarting the app

### No Weather/Events/Reminders?
1. Open **System Settings** > **Privacy & Security**
2. Grant permissions for:
   - Location Services
   - Calendar
   - Reminders
3. Restart the app

### Still Having Issues?
- Check the [FAQ](https://github.com/yourusername/dynamicNotch4mac#troubleshooting) in the main README
- [Open an issue](https://github.com/yourusername/dynamicNotch4mac/issues) on GitHub
- Make sure you have the latest version

## Auto-Start Setup

To make the app start automatically with macOS:

1. Use the installer script: `./install_production.sh`
2. When prompted, choose "Yes" for auto-start
3. The app will now launch every time you boot your Mac

To disable auto-start later:
```bash
launchctl unload ~/Library/LaunchAgents/com.dynamicnotch.app.plist
```

## Uninstalling

To completely remove the app:
1. Quit the app (right-click menu bar icon > Quit)
2. Delete `DynamicNotch4Mac.app` from Applications
3. Remove auto-start (if enabled):
   ```bash
   rm ~/Library/LaunchAgents/com.dynamicnotch.app.plist
   ```

---

**Enjoy your new dynamic notch experience!** 🎉

For more details, see the main [README](README.md).
