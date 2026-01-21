import Foundation
import Combine
import IOKit
import AppKit

/// 活跃状态监测器 - 检测用户是否在使用电脑
class ActivityMonitor: ObservableObject {
    
    // MARK: - Activity State
    
    enum ActivityState {
        case active     // 用户正在活跃使用
        case idle       // 用户闲置
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var currentState: ActivityState = .active
    @Published private(set) var wasLockedOrSleeping: Bool = false
    
    // MARK: - Settings
    
    private var idleThresholdSeconds: TimeInterval = 180  // 默认 3 分钟
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init(idleThresholdSeconds: TimeInterval = 180) {
        self.idleThresholdSeconds = idleThresholdSeconds
        setupNotifications()
        startMonitoring()
        print("👁️ ActivityMonitor initialized (idle threshold: \(Int(idleThresholdSeconds))s)")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 重置锁定/睡眠标志
    func resetLockOrSleepFlag() {
        wasLockedOrSleeping = false
    }
    
    /// 获取系统闲置时间（秒）
    func getSystemIdleSeconds() -> TimeInterval {
        var iterator: io_iterator_t = 0
        defer { IOObjectRelease(iterator) }
        
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterator) == KERN_SUCCESS else {
            return 0
        }
        
        let entry = IOIteratorNext(iterator)
        defer { IOObjectRelease(entry) }
        
        guard entry != 0 else { return 0 }
        
        var property: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &property, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = property?.takeRetainedValue() as? [String: Any],
              let hidIdleTime = dict["HIDIdleTime"] as? Int64 else {
            return 0
        }
        
        // HIDIdleTime 是纳秒，转换为秒
        return TimeInterval(hidIdleTime) / 1_000_000_000
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // 每秒检查一次闲置状态
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkIdleState() {
        let idleTime = getSystemIdleSeconds()
        let newState: ActivityState = idleTime >= idleThresholdSeconds ? .idle : .active
        
        if newState != currentState {
            currentState = newState
            print("🔄 Activity state changed: \(newState) (idle time: \(Int(idleTime))s, threshold: \(Int(idleThresholdSeconds))s)")
        }
    }
    
    private func setupNotifications() {
        let workspace = NSWorkspace.shared.notificationCenter
        let distCenter = DistributedNotificationCenter.default()
        
        // 监听唤醒
        workspace.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                print("🌅 System woke up")
                self?.wasLockedOrSleeping = true
                self?.currentState = .active
            }
            .store(in: &cancellables)
        
        // 监听睡眠
        workspace.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                print("😴 System will sleep")
                self?.wasLockedOrSleeping = true
                self?.currentState = .idle
            }
            .store(in: &cancellables)
        
        // 监听锁屏 (使用 DistributedNotificationCenter)
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🔒 Screen locked (DistributedNotification)")
            self?.wasLockedOrSleeping = true
            self?.currentState = .idle
        }
        
        // 监听解锁
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🔓 Screen unlocked (DistributedNotification)")
            self?.wasLockedOrSleeping = true
            self?.currentState = .active
        }
        
        // 监听屏幕保护启动
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstart"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🖼️ Screen saver started")
            self?.wasLockedOrSleeping = true
            self?.currentState = .idle
        }
        
        // 监听屏幕保护停止
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstop"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🖼️ Screen saver stopped")
            self?.wasLockedOrSleeping = true
            self?.currentState = .active
        }
        
        // 监听会话变化（备用检测）
        workspace.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .sink { [weak self] _ in
                print("🔒 Session resigned active")
                self?.wasLockedOrSleeping = true
                self?.currentState = .idle
            }
            .store(in: &cancellables)
        
        workspace.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in
                print("🔓 Session became active")
                self?.wasLockedOrSleeping = true
                self?.currentState = .active
            }
            .store(in: &cancellables)
    }
}
