import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var activityMonitor: ActivityMonitor?
    private var timerEngine: TimerEngine?
    private var overlayWindowController: OverlayWindowController?
    private var settingsStore: SettingsStore?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化 Settings Store
        settingsStore = SettingsStore()
        
        // 初始化 Activity Monitor
        activityMonitor = ActivityMonitor()
        
        // 初始化 Timer Engine (与 Activity Monitor 关联)
        timerEngine = TimerEngine(activityMonitor: activityMonitor)
        
        // 初始化 Overlay Window Controller
        overlayWindowController = OverlayWindowController()
        setupOverlayCallbacks()
        
        // 监听活跃状态变化
        activityMonitor?.$currentState
            .sink { [weak self] state in
                self?.handleActivityStateChange(state)
            }
            .store(in: &cancellables)
        
        // 监听计时器状态变化
        timerEngine?.$state
            .sink { [weak self] state in
                self?.handleTimerStateChange(state)
            }
            .store(in: &cancellables)
        
        // 初始化 Menu Bar Controller
        menuBarController = MenuBarController()
        menuBarController?.activityMonitor = activityMonitor
        menuBarController?.timerEngine = timerEngine
        menuBarController?.settingsStore = settingsStore
        
        // 隐藏主窗口（如果有）
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // 启动计时器
        timerEngine?.start()
        
        print("✅ MoveApp launched successfully")
        print("👁️ ActivityMonitor is now active")
        print("⏱️ TimerEngine started")
        
        // 打印当前系统 idle 时间（调试用）
        if let monitor = activityMonitor {
            let idleTime = monitor.getSystemIdleSeconds()
            print("📊 Current system idle time: \(String(format: "%.1f", idleTime))s")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timerEngine?.stop()
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
    
    // MARK: - Timer State Handler
    
    private func handleTimerStateChange(_ state: TimerEngine.TimerState) {
        switch state {
        case .running(let activeSeconds, let targetSeconds):
            let remaining = targetSeconds - activeSeconds
            if activeSeconds % 60 == 0 {  // 每分钟打印一次，避免日志过多
                print("⏱️ Timer running: \(activeSeconds)s / \(targetSeconds)s (remaining: \(remaining)s)")
            }
            // 隐藏 overlay（如果有的话）
            if overlayWindowController?.window?.isVisible == true {
                overlayWindowController?.hide()
            }
        case .paused(let reason):
            print("⏸️ Timer paused: \(reason)")
        case .alerting(let snoozeCount):
            print("🚨 ALERT! (snooze count: \(snoozeCount))")
            // 显示提醒 overlay
            showAlertOverlay(snoozeCount: snoozeCount)
        case .breakRunning(let remainingSeconds):
            if remainingSeconds % 10 == 0 || remainingSeconds <= 5 {
                print("🧘 Break: \(remainingSeconds)s remaining")
            }
            // 更新休息倒计时 overlay
            updateBreakOverlay(remainingSeconds: remainingSeconds)
        case .breakCompleted:
            print("🎉 Break completed!")
            // 显示完成卡片
            showCompletionOverlay()
        case .snoozing(let untilDate, let snoozeCount):
            print("😴 Snoozing until \(untilDate) (count: \(snoozeCount))")
            // 隐藏 overlay
            overlayWindowController?.hide()
        }
    }
    
    // MARK: - Overlay Management
    
    private func setupOverlayCallbacks() {
        overlayWindowController?.onMoveClicked = { [weak self] in
            print("✅ User clicked 'I'm Moving'")
            self?.timerEngine?.beginBreak()
        }
        
        overlayWindowController?.onSnoozeClicked = { [weak self] in
            print("😴 User clicked 'Snooze'")
            self?.timerEngine?.snooze()
        }
    }
    
    private func showAlertOverlay(snoozeCount: Int) {
        overlayWindowController?.show(
            on: NSScreen.main,
            contentType: .alert(snoozeCount: snoozeCount)
        )
    }
    
    private func updateBreakOverlay(remainingSeconds: Int) {
        // 如果 overlay 已经显示，只需要更新内容
        // 否则显示新的 overlay
        if overlayWindowController?.window?.isVisible == true {
            // 更新内容
            overlayWindowController?.show(
                on: NSScreen.main,
                contentType: .breakTime(remainingSeconds: remainingSeconds)
            )
        } else {
            // 首次显示
            overlayWindowController?.show(
                on: NSScreen.main,
                contentType: .breakTime(remainingSeconds: remainingSeconds)
            )
        }
    }
    
    private func showCompletionOverlay() {
        overlayWindowController?.show(
            on: NSScreen.main,
            contentType: .breakCompleted
        )
    }
}
