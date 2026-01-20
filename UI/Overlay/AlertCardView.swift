import SwiftUI

/// 提醒卡片 - "MOVE! MOVE! MOVE!" 提醒界面
struct AlertCardView: View {
    
    // MARK: - Properties
    
    var onMoveClicked: () -> Void
    var onSnoozeClicked: () -> Void
    var showSnoozeButton: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("MOVE! MOVE! MOVE!")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 说明文字
            Text("You've been on screen for 60 minutes.")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
                .frame(height: 20)
            
            // 按钮组
            VStack(spacing: 16) {
                // Primary 按钮
                Button(action: onMoveClicked) {
                    Text("I'm Moving")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // Secondary 按钮（Snooze）
                if showSnoozeButton {
                    Button(action: onSnoozeClicked) {
                        Text("Snooze 5 min")
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: 300)
        }
        .padding(50)
        .frame(width: 500, height: 400)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview("Alert Card - With Snooze") {
    ZStack {
        Color.black.opacity(0.3)
        AlertCardView(
            onMoveClicked: { print("Move clicked") },
            onSnoozeClicked: { print("Snooze clicked") },
            showSnoozeButton: true
        )
    }
    .frame(width: 800, height: 600)
}

#Preview("Alert Card - No Snooze") {
    ZStack {
        Color.black.opacity(0.3)
        AlertCardView(
            onMoveClicked: { print("Move clicked") },
            onSnoozeClicked: { print("Snooze clicked") },
            showSnoozeButton: false
        )
    }
    .frame(width: 800, height: 600)
}
