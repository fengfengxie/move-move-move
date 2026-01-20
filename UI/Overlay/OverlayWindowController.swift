import Cocoa
import SwiftUI

/// Overlay 窗口控制器 - 管理全屏提醒遮罩
class OverlayWindowController: NSWindowController {
    
    // MARK: - Initialization
    
    convenience init() {
        // 创建无边框窗口
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口属性
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.hasShadow = false
        
        // 暂时使用空白内容
        let hostingView = NSHostingView(rootView: OverlayContentView())
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    // MARK: - Public Methods
    
    /// 显示遮罩在指定屏幕上
    func show(on screen: NSScreen? = NSScreen.main) {
        guard let screen = screen, let window = window else { return }
        
        // 设置窗口大小为屏幕大小
        window.setFrame(screen.frame, display: true)
        
        // 显示窗口
        window.orderFrontRegardless()
        
        print("🖼️ Overlay window shown")
    }
    
    /// 隐藏遮罩
    func hide() {
        window?.orderOut(nil)
        print("🙈 Overlay window hidden")
    }
}

// MARK: - Overlay Content View

private struct OverlayContentView: View {
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 居中卡片（占位符）
            VStack(spacing: 20) {
                Text("Overlay Placeholder")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("This will be replaced with AlertCardView and BreakCardView")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}
