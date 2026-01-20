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
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    init() {
        print("⏱️ TimerEngine initialized")
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动计时器
    func start() {
        guard timer == nil else { return }
        
        state = .running(activeSeconds: 0, targetSeconds: intervalSeconds)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        print("▶️ TimerEngine started")
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
        
        let untilDate = Date().addingTimeInterval(5 * 60)  // 5 分钟后
        state = .snoozing(untilDate: untilDate, snoozeCount: snoozeCount + 1)
        
        print("😴 Snoozing until \(untilDate), count: \(snoozeCount + 1)")
    }
    
    /// 开始休息倒计时
    func beginBreak() {
        state = .breakRunning(remainingSeconds: breakDurationSeconds)
        print("🧘 Break started: \(breakDurationSeconds)s")
    }
    
    // MARK: - Private Methods
    
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
                // Snooze 结束，重新触发提醒
                state = .alerting(snoozeCount: snoozeCount)
                print("⏰ Snooze ended, alerting again")
            }
            
        default:
            break
        }
    }
    
    /// 完成一次休息
    private func completeBreak() {
        breaksToday += 1
        print("✅ Break completed! Total today: \(breaksToday)")
        
        // 稍后重置周期
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resetCycle()
        }
    }
}
