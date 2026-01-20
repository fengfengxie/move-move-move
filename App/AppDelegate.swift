import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var activityMonitor: ActivityMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化 Activity Monitor
        activityMonitor = ActivityMonitor()
        
        // 监听活跃状态变化
        activityMonitor?.$currentState
            .sink { [weak self] state in
                self?.handleActivityStateChange(state)
            }
            .store(in: &cancellables)
        
        // 初始化 Menu Bar Controller
        menuBarController = MenuBarController()
        menuBarController?.activityMonitor = activityMonitor
        
        // 隐藏主窗口（如果有）
        NSApplication.shared.setActivationPolicy(.accessory)
        
        print("✅ MoveApp launched successfully")
        print("👁️ ActivityMonitor is now active")
        
        // 打印当前系统 idle 时间（调试用）
        if let monitor = activityMonitor {
            let idleTime = monitor.getSystemIdleSeconds()
            print("📊 Current system idle time: \(String(format: "%.1f", idleTime))s")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 MoveApp terminated")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Activity State Handler
    
    private func handleActivityStateChange(_ state: ActivityMonitor.ActivityState) {
        switch state {
        case .active:
            print("🟢 User is ACTIVE")
        case .idle:
            print("🟡 User is IDLE")
        }
    }
}
