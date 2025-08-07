# 🤝 Contributing to DynamicNotch4Mac

Thank you for your interest in contributing! This guide will help you get started.

## 🚀 Quick Start for Developers

### Prerequisites
- macOS 13.0+ 
- Xcode 15.0+
- Swift 5.9+
- Git

### Development Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/dynamicNotch4mac.git
cd dynamicNotch4mac

# Build for development
./build_production.sh

# Or use the master build script
./build_release.sh
```

## 📁 Project Structure

```
DynamicNotch4Mac/
├── Sources/                    # Swift source code
│   ├── App.swift              # App entry point
│   ├── AppDelegate.swift      # Core app logic
│   └── ContentView.swift      # SwiftUI interface
├── Scripts/                   # Build and deployment scripts
├── DynamicNotch4Mac.app/     # Built application bundle
├── Package.swift             # Swift Package Manager
└── Documentation/            # User guides and docs
```

## 🛠 Build Scripts

| Script | Purpose |
|--------|---------|
| `build_production.sh` | Build app bundle only |
| `build_release.sh` | Complete build + DMG creation |
| `create_dmg.sh` | Create installer DMG |
| `codesign_and_notarize.sh` | Code signing & notarization |
| `install_production.sh` | Local installation script |

## 🔨 Development Workflow

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Make** your changes
4. **Test** thoroughly: `./build_production.sh && open DynamicNotch4Mac.app`
5. **Commit** with clear messages: `git commit -m "Add amazing feature"`
6. **Push** to your fork: `git push origin feature/amazing-feature`
7. **Open** a Pull Request

## 📝 Code Style Guidelines

### Swift Code
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistent formatting
- Include comprehensive error handling
- Add logging for significant operations

### Comments & Documentation
- Document public APIs
- Use `// MARK:` to organize code sections
- Explain complex algorithms or business logic
- Update README for user-facing changes

## 🧪 Testing

### Manual Testing Checklist
- [ ] App builds successfully
- [ ] Permissions prompt correctly
- [ ] Dynamic notch appears/disappears
- [ ] File drag & drop works
- [ ] Calendar/reminders integration
- [ ] Menu bar functionality
- [ ] DMG installer works

### Automated Testing
```bash
# Run linter
swiftlint

# Build test
./build_production.sh

# DMG test
./create_dmg.sh
```

## 🎯 Areas for Contribution

### 🌟 User Features
- New notch display modes
- Additional data sources (Music, Mail, etc.)
- Customization options
- Keyboard shortcuts
- Themes and appearance

### 🔧 Technical Improvements
- Performance optimizations
- Memory usage reduction
- Better error handling
- Accessibility improvements
- Localization

### 📚 Documentation
- User guides and tutorials
- Video demonstrations
- Translation to other languages
- FAQ improvements

### 🐛 Bug Fixes
- Check [Issues](https://github.com/yourusername/dynamicNotch4mac/issues) for known bugs
- Test on different macOS versions
- Fix edge cases and error conditions

## 🚨 Important Guidelines

### Privacy & Security
- Never access user data without proper permissions
- Include usage descriptions for all sensitive data
- Follow Apple's privacy guidelines
- Test permission flows thoroughly

### Performance
- Minimize CPU usage (app runs continuously)
- Efficient memory management
- Avoid blocking the main thread
- Test with large datasets (many files, events, etc.)

### Compatibility
- Support macOS 13.0+
- Universal binary (Apple Silicon + Intel)
- Test on different screen sizes/resolutions
- Handle edge cases gracefully

## 📋 Pull Request Process

1. **Update** documentation if needed
2. **Test** on a clean system
3. **Follow** the PR template
4. **Respond** to review feedback promptly
5. **Squash** commits before merging

### PR Template
```markdown
## What does this PR do?
Brief description of changes

## How to test?
Step-by-step testing instructions

## Screenshots (if applicable)
Visual changes or new features

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Manual testing performed
- [ ] Documentation updated
```

## 🎖 Recognition

Contributors will be:
- Listed in the main README
- Included in release notes
- Given credit in About dialog (for major contributions)

## 📞 Getting Help

- **Questions?** Open a [Discussion](https://github.com/yourusername/dynamicNotch4mac/discussions)
- **Bug reports?** Create an [Issue](https://github.com/yourusername/dynamicNotch4mac/issues)
- **Feature ideas?** Start a [Discussion](https://github.com/yourusername/dynamicNotch4mac/discussions)

## 📜 Code of Conduct

- Be respectful and inclusive
- Help others learn and grow
- Focus on constructive feedback
- Follow GitHub's community guidelines

---

**Thank you for contributing to DynamicNotch4Mac!** 🎉

Your contributions help make this project better for everyone.
