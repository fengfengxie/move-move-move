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
    
    // 开发模式：使用短间隔快速测试
    static let developmentMode = true  // 设为 true 启用快速测试（15秒触发提醒）
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var activityMonitor: ActivityMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    // 用于保存暂停时的进度
    private var currentActiveSeconds: Int = 0
    
    // Snooze 结束但用户闲置的标记
    private var snoozeEndedWhileIdle: Bool = false
    private var snoozeCountAfterSnooze: Int = 0
    
    // MARK: - Lifecycle
    
    init(activityMonitor: ActivityMonitor? = nil) {
        self.activityMonitor = activityMonitor
        
        // 开发模式：使用短间隔
        if Self.developmentMode {
            intervalSeconds = 15  // 15 秒后触发提醒
            breakDurationSeconds = 8  // 8 秒休息
            snoozeDurationSeconds = 10  // 10 秒 snooze
            print("🛠️ DEVELOPMENT MODE: Using short intervals (15s alert, 8s break, 10s snooze)")
        }
        
        setupActivityObserver()
        print("⏱️ TimerEngine initialized")
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动计时器
    func start() {
        guard timer == nil else { return }
        
        // 根据当前活跃状态决定初始状态
        if let monitor = activityMonitor, monitor.currentState == .idle {
            state = .paused(reason: .idle)
            print("▶️ TimerEngine started (but paused due to idle state)")
        } else {
            state = .running(activeSeconds: 0, targetSeconds: intervalSeconds)
            print("▶️ TimerEngine started")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
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
    
    /// 处理活跃状态变化
    private func handleActivityStateChange(_ activityState: ActivityMonitor.ActivityState) {
        switch state {
        case .running(let activeSeconds, _):
            if activityState == .idle {
                // 用户变为闲置，暂停计时
                state = .paused(reason: .idle)
                // 保存当前进度
                currentActiveSeconds = activeSeconds
                print("⏸️ Timer paused (idle), progress saved: \(activeSeconds)s")
            }
            
        case .paused(let reason):
            if activityState == .active && reason == .idle {
                // 用户重新活跃，恢复计时
                state = .running(activeSeconds: currentActiveSeconds, targetSeconds: intervalSeconds)
                print("▶️ Timer resumed (active), restored: \(currentActiveSeconds)s")
            }
            
        case .snoozing(_, _):
            // Snooze 期间不管活跃状态，等时间到
            break
            
        case .alerting, .breakRunning, .breakCompleted:
            // 这些状态不受活跃状态影响
            break
        }
    }
    
    /// 计时器 tick（每秒调用）
    private func tick() {
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
        print("✅ Break completed! Total today: \(breaksToday)")
        
        // 1秒后重置周期
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resetCycle()
        }
    }
}
