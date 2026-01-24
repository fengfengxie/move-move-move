# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Move!Move!Move! is a macOS menu bar application that reminds users to take regular breaks from screen time. It's a Swift-based app using SwiftUI + AppKit with no external dependencies.

## Build Commands

```bash
# Development build
./build.sh
swift run MoveApp

# Release build (creates .app bundle)
./build.sh release

# Release with code signing
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh release
CODESIGN_ADHOC=1 ./build.sh release  # Ad-hoc signing

# Open in Xcode
open Package.swift
```

## Architecture

### State Machine (Core/TimerEngine.swift)

The app is driven by a central state machine with these states:
- `running` - Counting active screen time toward the target interval
- `paused` - Timer paused (reasons: idle, locked, sleeping, manual)
- `alerting` - Full-screen "MOVE!" overlay displayed
- `snoozing` - User snoozed the alert (max 2 per cycle)
- `breakRunning` - Break countdown in progress
- `breakCompleted` - Break finished, showing success message

### Key Components

- **AppDelegate** (App/AppDelegate.swift) - Orchestrates all components, sets up Combine subscriptions for state changes
- **TimerEngine** (Core/TimerEngine.swift) - State machine managing work/break cycles
- **ActivityMonitor** (Core/ActivityMonitor.swift) - Uses IOKit HIDIdleTime to detect user idle (>180s)
- **SettingsStore** (Core/SettingsStore.swift) - UserDefaults-based persistence
- **MenuBarController** (UI/MenuBar/) - NSStatusItem with NSPopover
- **OverlayWindowController** (UI/Overlay/) - Full-screen transparent overlay with SwiftUI cards

### Data Flow

```
Activity Change → ActivityMonitor → TimerEngine (state change) → AppDelegate → UI Update
```

### Development Mode

Set `TimerEngine.developmentMode = true` for rapid testing with shortened intervals (15s work, 8s break, 10s snooze).

## Key Behaviors

- Timer auto-pauses on idle (>180s) and resumes on activity
- Timer resets to 0 on screen lock/sleep events
- Break/snooze progress is preserved during lock/sleep
- Screen auto-locks via AppleScript after break completion
- Daily break counter resets at midnight

## Platform Requirements

- macOS 13.0+
- Swift 5.9+
- LSUIElement app (no Dock icon)
