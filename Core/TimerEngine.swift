import Foundation
import Combine

/// 核心计时引擎 - 管理应用的主要计时逻辑和状态机
class TimerEngine: ObservableObject {
    
    // MARK: - Timer State
    
    /// 计时器状态
    enum TimerState {
        case running(activeSeconds: Int, targetSeconds: Int)
        case paused(reason: PauseReason)
        case alerting(snoozeCount: Int)
        case breakRunning(remainingSeconds: Int)
        case breakCompleted  // 休息完成，显示成功消息
        case snoozing(untilDate: Date, snoozeCount: Int)
    }
    
    /// 暂停原因
    enum PauseReason {
        case idle           // 用户闲置
        case locked         // 屏幕锁定
        case sleeping       // 系统睡眠
        case manual         // 手动暂停
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var state: TimerState = .paused(reason: .manual)
    @Published private(set) var breaksToday: Int = 0
    
    // MARK: - Settings
    
    private var intervalSeconds: Int = 60 * 60  // 默认 60 分钟
    private var breakDurationSeconds: Int = 60  // 默认 60 秒
    private var snoozeDurationSeconds: Int = 5 * 60  // 默认 5 分钟
    
    // Development mode: use short intervals for testing
    static let developmentMode = false
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var activityMonitor: ActivityMonitor?
    private var settingsStore: SettingsStore?
    private var cancellables = Set<AnyCancellable>()
    
    // 用于保存暂停时的进度
    private var currentActiveSeconds: Int = 0
    
    // Snooze 结束但用户闲置的标记
    private var snoozeEndedWhileIdle: Bool = false
    private var snoozeCountAfterSnooze: Int = 0
    private var pausedTickCount: Int = 0
    
    // MARK: - Lifecycle
    
    init(activityMonitor: ActivityMonitor? = nil, settingsStore: SettingsStore? = nil) {
        self.activityMonitor = activityMonitor
        self.settingsStore = settingsStore
        
        if Self.developmentMode {
            intervalSeconds = 15
            breakDurationSeconds = 8
            snoozeDurationSeconds = 10
            print("🛠️ DEVELOPMENT MODE: 15s alert, 8s break, 10s snooze")
        } else if let settings = settingsStore {
            intervalSeconds = settings.intervalMinutes * 60
            breakDurationSeconds = settings.breakSeconds
        }
        
        // 同步 breaksToday 从 SettingsStore
        if let settings = settingsStore {
            breaksToday = settings.breaksToday
        }
        
        setupActivityObserver()
        setupSettingsObserver()
        print("⏱️ TimerEngine initialized")
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动计时器
    func start() {
        guard timer == nil else { return }
        
        // Start based on current activity state
        if let monitor = activityMonitor, monitor.currentState == .idle {
            state = .paused(reason: .idle)
            print("▶️ TimerEngine started (but paused due to idle state)")
        } else {
            state = .running(activeSeconds: 0, targetSeconds: intervalSeconds)
            print("▶️ TimerEngine started")
        }
        
        // Create timer with fire date 1 second in the future to prevent immediate firing
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        newTimer.fireDate = Date(timeIntervalSinceNow: 1.0)
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    /// 停止计时器
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .paused(reason: .manual)
        print("⏸️ TimerEngine stopped")
    }
    
    /// 重置周期（开始新一轮计时）
    func resetCycle() {
        state = .running(activeSeconds: 0, targetSeconds: intervalSeconds)
        print("🔄 Cycle reset")
    }
    
    /// 进入 Snooze 模式
    func snooze() {
        guard case .alerting(let snoozeCount) = state else { return }
        
        let untilDate = Date().addingTimeInterval(TimeInterval(snoozeDurationSeconds))
        state = .snoozing(untilDate: untilDate, snoozeCount: snoozeCount + 1)
        
        let minutes = snoozeDurationSeconds / 60
        let seconds = snoozeDurationSeconds % 60
        let durationStr = minutes > 0 ? "\(minutes)m" : "\(seconds)s"
        print("😴 Snoozing for \(durationStr) until \(untilDate), count: \(snoozeCount + 1)")
    }
    
    /// 开始休息倒计时
    func beginBreak() {
        state = .breakRunning(remainingSeconds: breakDurationSeconds)
        print("🧘 Break started: \(breakDurationSeconds)s")
    }
    
    // MARK: - State Helpers
    
    /// 获取下次休息的剩余秒数（用于 UI 显示）
    func getNextBreakSeconds() -> Int? {
        switch state {
        case .running(let activeSeconds, let targetSeconds):
            return targetSeconds - activeSeconds
        case .paused:
            return intervalSeconds - currentActiveSeconds
        case .snoozing(let untilDate, _):
            // 计算 snooze 剩余时间
            let remaining = untilDate.timeIntervalSinceNow
            return max(0, Int(remaining))
        default:
            return nil
        }
    }
    
    /// 获取当前状态的描述文本
    func getStateDescription() -> String {
        switch state {
        case .running:
            return "Running"
        case .paused(let reason):
            switch reason {
            case .idle:
                return "Paused (Idle)"
            case .locked:
                return "Paused (Locked)"
            case .sleeping:
                return "Paused (Sleeping)"
            case .manual:
                return "Paused"
            }
        case .alerting:
            return "Alert!"
        case .breakRunning:
            return "Break Time"
        case .breakCompleted:
            return "Break Complete!"
        case .snoozing:
            return "Snoozed"
        }
    }
    
    /// 判断是否正在运行中（不含暂停）
    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }
    
    // MARK: - Debug Helpers
    
    /// 开发模式：手动触发提醒（用于测试）
    func debugTriggerAlert() {
        if Self.developmentMode {
            state = .alerting(snoozeCount: 0)
            print("🧪 DEBUG: Manually triggered alert")
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置活跃状态监听
    private func setupActivityObserver() {
        activityMonitor?.$currentState
            .sink { [weak self] state in
                self?.handleActivityStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    /// 设置设置变化监听
    private func setupSettingsObserver() {
        guard let settings = settingsStore else { return }
        
        // 监听 interval 变化（仅在非开发模式下）
        if !Self.developmentMode {
            settings.$intervalMinutes
                .sink { [weak self] minutes in
                    guard let self = self else { return }
                    self.intervalSeconds = minutes * 60
                    print("⚙️ Interval updated to \(minutes) minutes")
                    // 如果当前正在运行，需要重新计算
                    if case .running(let activeSeconds, _) = self.state {
                        self.state = .running(activeSeconds: activeSeconds, targetSeconds: self.intervalSeconds)
                    }
                }
                .store(in: &cancellables)
            
            // 监听 break duration 变化
            settings.$breakSeconds
                .sink { [weak self] seconds in
                    guard let self = self else { return }
                    self.breakDurationSeconds = seconds
                    print("⚙️ Break duration updated to \(seconds) seconds")
                }
                .store(in: &cancellables)
        }
    }
    
    /// 处理活跃状态变化
    private func handleActivityStateChange(_ activityState: ActivityMonitor.ActivityState) {
        switch state {
        case .running(let activeSeconds, _):
            if activityState == .idle {
                // Check if this is a lock/sleep event
                if let monitor = activityMonitor, monitor.wasLockedOrSleeping {
                    // Lock/sleep detected: reset to 0 and pause
                    print("🔒 Lock/sleep detected - resetting timer to 0 and pausing")
                    currentActiveSeconds = 0
                    state = .paused(reason: .locked)
                    monitor.resetLockOrSleepFlag()
                } else {
                    // Normal idle: pause and save progress
                    state = .paused(reason: .idle)
                    currentActiveSeconds = activeSeconds
                    print("⏸️ Timer paused (idle)")
                }
            }
            
        case .paused(let reason):
            if activityState == .active {
                // Resume from pause - just continue from current progress
                print("▶️ Resuming timer from \(reason) (continuing from \(currentActiveSeconds)s)")
                state = .running(activeSeconds: currentActiveSeconds, targetSeconds: intervalSeconds)
            }
            
        case .snoozing(_, _):
            // Snooze 期间不管活跃状态，等时间到
            break
            
        case .alerting, .breakRunning, .breakCompleted:
            // 这些状态不受活跃状态影响
            break
        }
    }
    
    /// Timer tick (called every second)
    private func tick() {
        // Reset paused tick counter when not paused
        if case .paused = state {
            pausedTickCount += 1
        } else {
            pausedTickCount = 0
        }
        
        switch state {
        case .running(let activeSeconds, let targetSeconds):
            let newActiveSeconds = activeSeconds + 1
            
            if newActiveSeconds >= targetSeconds {
                // 达到目标时间，触发提醒
                state = .alerting(snoozeCount: 0)
                print("⏰ Alert triggered!")
            } else {
                state = .running(activeSeconds: newActiveSeconds, targetSeconds: targetSeconds)
                currentActiveSeconds = newActiveSeconds
            }
            
        case .breakRunning(let remainingSeconds):
            let newRemaining = remainingSeconds - 1
            
            if newRemaining <= 0 {
                // 休息完成
                completeBreak()
            } else {
                state = .breakRunning(remainingSeconds: newRemaining)
            }
            
        case .snoozing(let untilDate, let snoozeCount):
            if Date() >= untilDate {
                // Snooze 结束，检查活跃状态
                if let monitor = activityMonitor, monitor.currentState == .active {
                    // 用户仍活跃，立即触发提醒
                    state = .alerting(snoozeCount: snoozeCount)
                    print("⏰ Snooze ended, alerting again (user active)")
                } else {
                    // 用户闲置，等待恢复活跃
                    snoozeEndedWhileIdle = true
                    snoozeCountAfterSnooze = snoozeCount
                    state = .paused(reason: .idle)
                    print("😴 Snooze ended but user idle, waiting for activity")
                }
            }
            
        case .paused(_):
            // 暂停期间需要检查是否 snooze 刚结束
            if snoozeEndedWhileIdle, let monitor = activityMonitor, monitor.currentState == .active {
                snoozeEndedWhileIdle = false
                state = .alerting(snoozeCount: snoozeCountAfterSnooze)
                print("⏰ User became active after snooze, alerting now")
            }
            
        default:
            break
        }
    }
    
    /// 完成一次休息
    private func completeBreak() {
        breaksToday += 1
        state = .breakCompleted
        
        // 记录到 SettingsStore 进行持久化
        settingsStore?.recordBreak()
        
        print("✅ Break completed! Total today: \(breaksToday)")
        
        // 2秒后锁定屏幕（给用户时间看到完成消息）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.lockScreen()
        }
        
        // 3秒后重置周期（在锁屏之后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.resetCycle()
        }
    }
    
    /// 锁定屏幕
    private func lockScreen() {
        // 在后台线程执行 AppleScript 避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "System Events"
                keystroke "q" using {control down, command down}
            end tell
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                if let error = error {
                    print("⚠️ Failed to lock screen: \(error)")
                } else {
                    print("🔒 Screen locked for privacy")
                }
            }
        }
    }
}
