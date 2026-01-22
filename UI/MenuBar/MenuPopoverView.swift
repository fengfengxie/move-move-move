import SwiftUI

struct MenuPopoverView: View {
    var activityMonitor: ActivityMonitor?
    var timerEngine: TimerEngine?
    @ObservedObject var settingsStore: SettingsStore
    
    @State private var currentIdleTime: TimeInterval = 0
    @State private var nextBreakSeconds: Int = 0
    @State private var timerStatus: String = "Paused"
    @State private var breaksToday: Int = 0
    @State private var timer: Timer?
    @State private var showSettings: Bool = false
    
    init(activityMonitor: ActivityMonitor? = nil, timerEngine: TimerEngine? = nil, settingsStore: SettingsStore) {
        self.activityMonitor = activityMonitor
        self.timerEngine = timerEngine
        self.settingsStore = settingsStore
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main Status
            statusView
            
            Divider()
            
            // Quick Settings
            if showSettings {
                quickSettingsView
                Divider()
            }
            
            // CTA Button
            ctaButton
            
            Divider()
            
            // Activity Monitor (Development Mode)
            if TimerEngine.developmentMode, let monitor = activityMonitor {
                activityMonitorView(monitor: monitor)
                Divider()
            }
            
            // Menu Items
            menuItemsView
        }
        .frame(width: 320)
        .onAppear {
            startUpdaters()
        }
        .onDisappear {
            stopUpdaters()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Move!Move!Move!")
                    .font(.system(size: 18, weight: .bold))
                if TimerEngine.developmentMode {
                    Text("Development Mode")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
        .padding()
    }
    
    private var statusView: some View {
        VStack(spacing: 12) {
            // Status Indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(timerStatus)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(statusColor)
                Spacer()
            }
            
            // Countdown Display
            VStack(spacing: 4) {
                Text("Next break in")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(formatTime(nextBreakSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(nextBreakSeconds > 0 ? .primary : .secondary)
                    .monospacedDigit()
            }
            
            // Stats
            HStack(spacing: 20) {
                statItem(label: "Breaks Today", value: "\(breaksToday)")
                Divider()
                    .frame(height: 30)
                statItem(label: "Interval", value: formatIntervalSetting())
            }
        }
        .padding()
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickSettingsView: some View {
        VStack(spacing: 12) {
            Text("Quick Settings")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Interval Setting
            VStack(alignment: .leading, spacing: 6) {
                Text("Work Interval")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    intervalButton(minutes: 45)
                    intervalButton(minutes: 50)
                    intervalButton(minutes: 55)
                }
            }
            
            // Break Duration Setting
            VStack(alignment: .leading, spacing: 6) {
                Text("Break Duration")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    breakButton(seconds: 60)
                    breakButton(seconds: 90)
                    breakButton(seconds: 120)
                }
            }
        }
        .padding()
    }
    
    private func intervalButton(minutes: Int) -> some View {
        Button(action: {
            settingsStore.intervalMinutes = minutes
            print("⚙️ Interval changed to \(minutes) min")
        }) {
            Text("\(minutes) min")
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(settingsStore.intervalMinutes == minutes ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(settingsStore.intervalMinutes == minutes ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func breakButton(seconds: Int) -> some View {
        Button(action: {
            settingsStore.breakSeconds = seconds
            print("⚙️ Break duration changed to \(seconds)s")
        }) {
            Text("\(seconds)s")
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(settingsStore.breakSeconds == seconds ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(settingsStore.breakSeconds == seconds ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var ctaButton: some View {
        Button(action: {
            timerEngine?.beginBreak()
            print("💪 Start break now")
        }) {
            HStack {
                Image(systemName: "figure.walk.motion")
                Text("Start a break now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .disabled(timerEngine == nil)
    }
    
    private func activityMonitorView(monitor: ActivityMonitor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧪 Activity Monitor")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack {
                Circle()
                    .fill(monitor.currentState == .active ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(monitor.currentState == .active ? "Active" : "Idle")
                    .font(.system(size: 11))
                Spacer()
                Text(formatIdleTime(currentIdleTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var menuItemsView: some View {
        VStack(spacing: 0) {
            // Settings Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showSettings ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Quick Settings")
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()
            .background(Color.clear)
            .foregroundColor(.primary)
            
            Divider()
            
            // TEST: Manual alert trigger (for development)
            if TimerEngine.developmentMode {
                Button(action: {
                    print("🧪 Manual test: Triggering alert")
                    timerEngine?.debugTriggerAlert()
                }) {
                    HStack {
                        Image(systemName: "ladybug")
                        Text("Test Alert")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding()
                .foregroundColor(.orange)
                
                Divider()
            }
            
            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        switch timerStatus {
        case "Running": return .green
        case "Alerting", "Snoozing": return .orange
        case "Break Running": return .blue
        default: return .secondary
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatIntervalSetting() -> String {
        if TimerEngine.developmentMode {
            return "15s"
        }
        let mins = settingsStore.intervalMinutes
        return "\(mins) min"
    }
    
    private func startUpdaters() {
        // 检查并重置每日计数（处理跨天情况）
        settingsStore.checkAndResetDailyCount()

        // 启动定时器更新 UI
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateTimerInfo()
            updateIdleTime()
        }
    }
    
    private func stopUpdaters() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimerInfo() {
        guard let engine = timerEngine else { return }
        
        // 更新状态
        timerStatus = engine.getStateDescription()
        
        // 更新剩余时间
        if let seconds = engine.getNextBreakSeconds() {
            nextBreakSeconds = seconds
        } else {
            nextBreakSeconds = 0
        }
        
        // 更新今日休息次数
        breaksToday = engine.breaksToday
    }
    
    private func updateIdleTime() {
        if let monitor = activityMonitor {
            currentIdleTime = monitor.getSystemIdleSeconds()
        }
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        if totalSeconds <= 0 {
            return "--:--"
        }
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatIdleTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    MenuPopoverView(settingsStore: SettingsStore())}