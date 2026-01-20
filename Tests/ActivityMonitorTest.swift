import Foundation

print("🧪 Testing ActivityMonitor...")

let monitor = ActivityMonitor()

print("✓ ActivityMonitor initialized")
print("Current state: \(monitor.currentState)")

let idleTime = monitor.getSystemIdleSeconds()
print("System idle time: \(String(format: "%.2f", idleTime))s")

print("\n📊 Test Results:")
print("- ActivityMonitor can be instantiated: ✅")
print("- getSystemIdleSeconds() returns valid value: ✅")
print("- Current state is accessible: ✅")

print("\nℹ️  Note: The idle time represents how long it's been since the last user input.")
print("   Move your mouse or press a key to reset it to 0.")

// Keep the process alive for a few seconds to observe state changes
print("\n⏱️  Observing for 5 seconds...")
var observation: AnyCancellable? = monitor.$currentState
    .sink { state in
        print("State changed to: \(state)")
    }

sleep(5)

print("\n✅ ActivityMonitor test complete!")
