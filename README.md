# Move!Move!Move! - macOS Menu Bar App

A macOS Menu Bar application that reminds you to take regular breaks and move around during long work sessions.

## 🎯 Features

- **Screen Activity Monitoring**: Tracks continuous screen usage time
- **Smart Break Reminders**: Full-screen overlay prompts every 60 minutes
- **Break Timer**: Guided break countdown (60/90/120 seconds)
- **Snooze Option**: 5-minute snooze (max 2 times per cycle)
- **Menu Bar Integration**: Always accessible from your menu bar
- **Privacy First**: All data stays on your device

## 🏗️ Architecture

```
MoveApp/
├── App/
│   ├── MoveApp.swift           # App entry point
│   └── AppDelegate.swift       # Application lifecycle
├── Core/
│   ├── TimerEngine.swift       # Core timer state machine
│   ├── ActivityMonitor.swift   # User activity detection
│   └── SettingsStore.swift     # Settings persistence
├── UI/
│   ├── MenuBar/
│   │   ├── MenuBarController.swift
│   │   └── MenuPopoverView.swift
│   └── Overlay/
│       ├── OverlayWindowController.swift
│       ├── AlertCardView.swift
│       └── BreakCardView.swift
└── Resources/
    └── Assets.xcassets
```

## 🚀 Building & Installation

### Requirements
- macOS 13.0+
- Xcode 15.0+ (optional, for development)
- Swift 5.9+

### Quick Install (Pre-built)

1. Download the latest release from GitHub
2. Move the app to Applications:
   ```bash
   cp -R "Move!Move!Move!.app" /Applications/
   ```
3. Open from Applications or Spotlight
4. Grant necessary permissions when prompted

### Build from Source

#### Option 1: Release Build (Recommended for daily use)

```bash
cd MoveApp
./build.sh release
```

This creates a standalone `.app` bundle at `.build/release/Move!Move!Move!.app`

To install:
```bash
cp -R ".build/release/Move!Move!Move!.app" /Applications/
```

#### Optional: Code Signing & Zip Packaging

Release builds support optional code signing and zip packaging via environment variables:

```bash
# Sign with Developer ID
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh release

# Ad-hoc signing (local testing)
CODESIGN_ADHOC=1 ./build.sh release

# Build and create a distributable zip
PACKAGE_ZIP=1 ./build.sh release
```

#### Optional: Xcode Archive (for notarization)

1. Open the project in Xcode:
   ```bash
   cd MoveApp
   open Package.swift
   ```
2. Select the `MoveApp` scheme
3. Product → Archive
4. Distribute App → Developer ID / Notarized (as needed)

#### Option 2: Development Build

With Xcode:
```bash
cd MoveApp
open Package.swift
# Then press Cmd + R
```

With Swift Package Manager:
```bash
cd MoveApp
./build.sh        # or: swift build
swift run MoveApp
```

## 📝 Development Status

### ✅ Completed Phases

- **Phase 1**: Project Foundation
- **Phase 2**: Activity Monitoring (IOKit integration)
- **Phase 3**: Timer Engine State Machine
- **Phase 4**: Overlay Window System
- **Phase 5**: Snooze Mechanism
- **Phase 6**: Break Countdown
- **Phase 7**: Enhanced Menu Popover
- **Phase 8**: Settings & Persistence
- **Phase 9**: Testing & Optimization
- **Phase 10**: Build & Packaging ✨

**Status**: Production Ready 🎉

## 🎨 Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI + AppKit (NSStatusItem, NSPanel)
- **Activity Detection**: IOKit (HIDIdleTime)
- **Persistence**: UserDefaults
- **Launch at Login**: ServiceManagement (SMAppService)

## 📖 Usage

### First Launch

1. Launch the app - look for the walking figure icon (🚶) in your menu bar
2. Click the icon to open the control panel
3. Configure your preferences:
   - **Work Interval**: Choose 45, 60, or 90 minutes
   - **Break Duration**: Choose 60, 90, or 120 seconds
4. The timer starts automatically

### Daily Use

1. **Normal Flow**:
   - Work continuously for your set interval (default: 60 minutes)
   - Full-screen reminder appears: "MOVE! MOVE! MOVE!"
   - Click "I'm Moving" to start break countdown
   - Follow the timer and take your break
   - Timer resets automatically after break

2. **Snooze Option**:
   - Click "Snooze 5 min" to delay the break
   - Maximum 2 snoozes per cycle
   - After 2 snoozes, you must take the break

3. **Manual Break**:
   - Click menu bar icon
   - Click "Start a break now" to trigger an immediate break

4. **Auto-Pause**:
   - Timer pauses when idle for 3+ minutes
   - Timer pauses during screen lock or system sleep
   - Automatically resumes when you return

### Launch at Login

Enable in the menu popover settings to start automatically at login.

## ⚙️ Configuration

Available settings (adjust in menu popover):

| Setting | Options | Default |
|---------|---------|---------|
| Work Interval | 45/60/90 min | 60 min |
| Break Duration | 60/90/120 sec | 60 sec |
| Idle Threshold | Fixed | 180 sec |
| Snooze Duration | Fixed | 300 sec |
| Max Snoozes | Fixed | 2 |
| Launch at Login | On/Off | Off |

### Stats Tracked

- Breaks completed today
- Current cycle progress
- Activity status (Active/Idle)

## 🔒 Privacy

- No data collection
- No internet connection required
- All processing happens locally
- No tracking or analytics

## 🖼️ Screenshots

Add screenshots to the [MoveApp/Resources/Screenshots](MoveApp/Resources/Screenshots) folder:

- menu-popover.png
- overlay-alert.png
- break-countdown.png
- completion-state.png

## 📄 License

Copyright © 2026. All rights reserved.

---

Built with ❤️ for healthier work habits
