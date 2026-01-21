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
        }
    }
    
    private func setupNotifications() {
        let workspace = NSWorkspace.shared.notificationCenter
        let distCenter = DistributedNotificationCenter.default()
        
        // Monitor wake
        workspace.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                print("🌅 System WOKE UP")
                self?.currentState = .active
            }
            .store(in: &cancellables)
        
        // Monitor sleep
        workspace.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                print("😴 System SLEEPING - setting wasLockedOrSleeping=true")
                self?.wasLockedOrSleeping = true  // Set flag when going to sleep
                self?.currentState = .idle
            }
            .store(in: &cancellables)
        
        // Monitor screen lock (using DistributedNotificationCenter)
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🔒 Screen LOCKED - setting wasLockedOrSleeping=true")
            self?.wasLockedOrSleeping = true  // Set flag when locking
            self?.currentState = .idle
        }
        
        // Monitor screen unlock
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            print("🔓 Screen UNLOCKED")
            self?.currentState = .active
        }
        
        // Monitor screen saver start
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstart"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            self?.wasLockedOrSleeping = true  // Set flag when screensaver starts
            self?.currentState = .idle
        }
        
        // Monitor screen saver stop
        distCenter.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstop"), 
                              object: nil, 
                              queue: .main) { [weak self] _ in
            self?.currentState = .active
        }
        
        // Monitor session changes (backup detection)
        workspace.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .sink { [weak self] _ in
                self?.wasLockedOrSleeping = true  // Set flag when session resigns
                self?.currentState = .idle
            }
            .store(in: &cancellables)
        
        workspace.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.currentState = .active
            }
            .store(in: &cancellables)
    }
}
