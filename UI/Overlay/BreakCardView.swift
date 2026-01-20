import SwiftUI

/// 休息倒计时卡片
struct BreakCardView: View {
    
    // MARK: - Properties
    
    var remainingSeconds: Int
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        // 假设总时长 60 秒，实际应该从 SettingsStore 获取
        let totalSeconds = 60.0
        return max(0, min(1, Double(remainingSeconds) / totalSeconds))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 40) {
            // 标题
            Text("Take a Break")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 倒计时环形进度
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // 倒计时数字
                Text("\(remainingSeconds)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // 提示文案
            VStack(spacing: 8) {
                Text("Stand up. Walk a bit. Drink water.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(50)
        .frame(width: 500, height: 500)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview("Break Card - 60s") {
    ZStack {
        Color.black.opacity(0.3)
        BreakCardView(remainingSeconds: 60)
    }
    .frame(width: 800, height: 600)
}

#Preview("Break Card - 30s") {
    ZStack {
        Color.black.opacity(0.3)
        BreakCardView(remainingSeconds: 30)
    }
    .frame(width: 800, height: 600)
}

#Preview("Break Card - 5s") {
    ZStack {
        Color.black.opacity(0.3)
        BreakCardView(remainingSeconds: 5)
    }
    .frame(width: 800, height: 600)
}
