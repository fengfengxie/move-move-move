import SwiftUI

/// 完成卡片 - 休息完成提示
struct CompletionCardView: View {
    
    var body: some View {
        VStack(spacing: 30) {
            // 成功图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            // 标题
            Text("Nice. Back to work.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 副标题
            Text("Break completed successfully!")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(60)
        .frame(width: 500, height: 400)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.3)
        CompletionCardView()
    }
    .frame(width: 800, height: 600)
}
