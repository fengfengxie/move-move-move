import SwiftUI

struct MenuPopoverView: View {
    var activityMonitor: ActivityMonitor?
    var timerEngine: TimerEngine?
    
    @State private var currentIdleTime: TimeInterval = 0
    @State private var nextBreakSeconds: Int = 0
    @State private var timerStatus: String = "Paused"
    @State private var breaksToday: Int = 0
    @State private var timer: Timer?
    
    init(activityMonitor: ActivityMonitor? = nil, timerEngine: TimerEngine? = nil) {
        self.activityMonitor = activityMonitor
        self.timerEngine = timerEngine
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // App 标题
            Text("Move!Move!Move!")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // 状态信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(timerStatus)
                        .foregroundColor(timerStatus == "Running" ? .green : .orange)
                }
                
                HStack {
                    Text("Next break in:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTime(nextBreakSeconds))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(nextBreakSeconds > 0 ? .primary : .secondary)
                }
                
                HStack {
                    Text("Breaks today:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(breaksToday)")
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Divider()
            
            // Activity Monitor Status (Phase 2 Test)
            if let monitor = activityMonitor {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Monitor")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(monitor.currentState == .active ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)
                        Text(monitor.currentState == .active ? "Active" : "Idle")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Idle time:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatIdleTime(currentIdleTime))
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
            }
            
            // CTA 按钮
            Button(action: {
                timerEngine?.beginBreak()
                print("Start break now")
            }) {
                Text("Start a break now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
            
            // 菜单项
            VStack(spacing: 8) {
                // TEST: Manual alert trigger (for development)
                if TimerEngine.developmentMode {
                    Button(action: {
                        print("🧪 Manual test: Triggering alert")
                        timerEngine?.debugTriggerAlert()
                    }) {
                        HStack {
                            Text("🧪 Test Alert")
                            Spacer()
                            Image(systemName: "ladybug")
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                    
                    Divider()
                }
                
                Button(action: {
                    print("Settings...")
                }) {
                    HStack {
                        Text("Settings...")
                        Spacer()
                        Image(systemName: "gearshape")
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Text("Quit")
                        Spacer()
                        Image(systemName: "xmark.circle")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            startUpdaters()
        }
        .onDisappear {
            stopUpdaters()
        }
    }
    
    private func startUpdaters() {
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
    MenuPopoverView()
}
