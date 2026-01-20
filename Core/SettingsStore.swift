import Foundation
import SwiftUI
import ServiceManagement

/// 设置存储 - 管理用户设置的持久化
class SettingsStore: ObservableObject {
    
    // MARK: - Settings Keys
    
    private enum Keys {
        static let intervalMinutes = "intervalMinutes"
        static let breakSeconds = "breakSeconds"
        static let idleThresholdSeconds = "idleThresholdSeconds"
        static let launchAtLogin = "launchAtLogin"
        static let breaksToday = "breaksToday"
        static let lastBreakDate = "lastBreakDate"
    }
    
    // MARK: - Published Properties
    
    @Published var intervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(intervalMinutes, forKey: Keys.intervalMinutes)
        }
    }
    
    @Published var breakSeconds: Int {
        didSet {
            UserDefaults.standard.set(breakSeconds, forKey: Keys.breakSeconds)
        }
    }
    
    @Published var idleThresholdSeconds: Int {
        didSet {
            UserDefaults.standard.set(idleThresholdSeconds, forKey: Keys.idleThresholdSeconds)
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            configureLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published var breaksToday: Int {
        didSet {
            UserDefaults.standard.set(breaksToday, forKey: Keys.breaksToday)
        }
    }
    
    private var lastBreakDate: Date? {
        didSet {
            if let date = lastBreakDate {
                UserDefaults.standard.set(date, forKey: Keys.lastBreakDate)
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // 加载设置，如果不存在则使用默认值
        self.intervalMinutes = UserDefaults.standard.object(forKey: Keys.intervalMinutes) as? Int ?? 60
        self.breakSeconds = UserDefaults.standard.object(forKey: Keys.breakSeconds) as? Int ?? 60
        self.idleThresholdSeconds = UserDefaults.standard.object(forKey: Keys.idleThresholdSeconds) as? Int ?? 180
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.breaksToday = UserDefaults.standard.integer(forKey: Keys.breaksToday)
        self.lastBreakDate = UserDefaults.standard.object(forKey: Keys.lastBreakDate) as? Date
        
        // 检查是否需要重置今日计数
        checkAndResetDailyCount()
        
        print("⚙️ SettingsStore initialized")
    }
    
    // MARK: - Public Methods
    
    /// 检查并重置每日计数（如果是新的一天）
    func checkAndResetDailyCount() {
        guard let lastDate = lastBreakDate else {
            // 首次运行，初始化日期
            lastBreakDate = Date()
            return
        }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            // 不是今天，重置计数
            breaksToday = 0
            lastBreakDate = Date()
            print("🗓️ New day detected, breaks count reset")
        }
    }
    
    /// 记录一次休息
    func recordBreak() {
        breaksToday += 1
        lastBreakDate = Date()
        print("📝 Break recorded, total today: \(breaksToday)")
    }
    
    // MARK: - Private Methods
    
    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("🚀 Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("🚫 Launch at login disabled")
                }
            } catch {
                print("❌ Failed to configure launch at login: \(error.localizedDescription)")
            }
        } else {
            // macOS 12 及更早版本的兼容处理
            print("⚠️ Launch at login requires macOS 13+")
        }    }
}