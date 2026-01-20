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

## 🚀 Building

### Requirements
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

### Build with Xcode

1. Open the project in Xcode:
   ```bash
   cd MoveApp
   open Package.swift
   ```

2. Select the `MoveApp` scheme

3. Build and run: `Cmd + R`

### Build with Swift Package Manager

```bash
cd MoveApp
swift build
swift run MoveApp
```

## 📝 Development Status

### Phase 1: ✅ Project Foundation (Completed)
- [x] Project structure created
- [x] Menu Bar app setup with NSStatusItem
- [x] Basic popover implementation
- [x] Core module skeletons (TimerEngine, ActivityMonitor, SettingsStore)
- [x] Overlay window framework
- [x] AlertCardView and BreakCardView UI components

### Next Phases
- [ ] Phase 2: Activity Monitoring Integration
- [ ] Phase 3: Timer Engine Logic
- [ ] Phase 4: Overlay Window Triggers
- [ ] Phase 5: Snooze Mechanism
- [ ] Phase 6: Break Countdown
- [ ] Phase 7: Menu Popover Enhancement
- [ ] Phase 8: Settings & Persistence
- [ ] Phase 9: Testing & Optimization
- [ ] Phase 10: Packaging & Distribution

## 🎨 Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI + AppKit (NSStatusItem, NSPanel)
- **Activity Detection**: IOKit (HIDIdleTime)
- **Persistence**: UserDefaults
- **Launch at Login**: ServiceManagement (SMAppService)

## 📖 Usage

1. The app runs in your menu bar (look for the walking figure icon 🚶)
2. Click the icon to see status and settings
3. Work for 60 minutes, and you'll get a break reminder
4. Click "I'm Moving" to start your break countdown
5. Or click "Snooze 5 min" to delay (max 2 times)

## ⚙️ Configuration

Default settings:
- **Work Interval**: 60 minutes
- **Break Duration**: 60 seconds
- **Idle Threshold**: 3 minutes
- **Snooze Duration**: 5 minutes (max 2 snoozes)

## 🔒 Privacy

- No data collection
- No internet connection required
- All processing happens locally
- No tracking or analytics

## 📄 License

Copyright © 2026. All rights reserved.

---

Built with ❤️ for healthier work habits
