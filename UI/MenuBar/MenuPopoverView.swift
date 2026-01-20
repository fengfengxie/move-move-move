import SwiftUI

struct MenuPopoverView: View {
    var activityMonitor: ActivityMonitor?
    @State private var currentIdleTime: TimeInterval = 0
    @State private var timer: Timer?
    
    init(activityMonitor: ActivityMonitor? = nil) {
        self.activityMonitor = activityMonitor
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // App 标题
            Text("Move!Move!Move!")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
            
            // 状态信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Running")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Next break in:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("--:--")
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Breaks today:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("0")
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Divider()
            
            // CTA 按钮
            Button(action: {
                print("Start break now")
            }) {
                Text("Start a break now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
            
            // 菜单项
            VStack(spacing: 8) {
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
            startIdleTimeUpdater()
        }
        .onDisappear {
            stopIdleTimeUpdater()
        }
    }
    
    private func startIdleTimeUpdater() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let monitor = activityMonitor {
                currentIdleTime = monitor.getSystemIdleSeconds()
            }
        }
    }
    
    private func stopIdleTimeUpdater() {
        timer?.invalidate()
        timer = nil
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
