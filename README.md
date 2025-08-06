# DynamicNotch4Mac

A macOS menu bar application that provides a simple file tray functionality using the dynamic notch area for MacBooks.

## Features

- **Menu Bar Integration**: Easy access through the macOS menu bar
- **File Tray**: 
  - Drag and drop files into the tray
  - Access files by hovering over the notch area
  - Remove files with a simple click
  - Visual file type indicators
- **Dynamic Notch Support**: Works with DynamicNotchKit to provide smooth notch interactions
- **Universal Compatibility**: Works on Macs with and without notches (floating style on non-notch Macs)

## Requirements

- macOS 13.0 or later
- MacBook with notch (for full notch experience) or any Mac (floating style)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/dynamicNotch4mac.git
cd dynamicNotch4mac
```

2. Build the project:
```bash
swift build
```

3. Run the application:
```bash
swift run
```

## Usage

1. **Launch the App**: Run the application and it will appear as a menu bar icon (display symbol)
2. **Access Controls**: Click the menu bar icon to open the file tray control panel
3. **Add Files**: Drag and drop files into the drop zone in the control panel
4. **Access Files**: Move your mouse to the top center of the screen (notch area) to see your file tray
5. **Manage Files**: 
   - Click the X button to remove files
   - Drag files out of the tray to other applications
   - Click the trash icon to clear all files

## File Tray Features

### Drag and Drop Support
- Drop files directly into the control panel
- Drop files into the notch area when it's visible
- Support for all file types with appropriate icons

### File Management
- Visual file type indicators (documents, images, videos, etc.)
- File name display with truncation for long names
- Easy removal with click-to-delete functionality

### Notch Integration
- Automatically appears when mouse enters notch area
- Automatically hides when mouse leaves notch area
- Smooth animations powered by DynamicNotchKit

## Technical Details

This application uses:
- **SwiftUI** for the user interface
- **DynamicNotchKit** for notch functionality
- **AppKit** for menu bar integration
- **UniformTypeIdentifiers** for file type handling
- **Swift Package Manager** for dependency management

## Dependencies

- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) - The core framework for dynamic notch functionality

## Development

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) by MrKai77 for providing the core notch functionality
- Apple for SwiftUI and the macOS platform 