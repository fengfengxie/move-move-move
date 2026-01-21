import Cocoa
import SwiftUI

/// Overlay 窗口控制器 - 管理全屏提醒遮罩
class OverlayWindowController: NSWindowController {
    
    // MARK: - Content Type
    
    enum ContentType {
        case alert(snoozeCount: Int)
        case breakTime(remainingSeconds: Int)
        case breakCompleted
    }
    
    // MARK: - Properties
    
    var onMoveClicked: (() -> Void)?
    var onSnoozeClicked: (() -> Void)?
    
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
        
        self.init(window: window)
    }
    
    // MARK: - Public Methods
    
    /// 显示遮罩在指定屏幕上，并设置内容
    func show(on screen: NSScreen? = NSScreen.main, contentType: ContentType) {
        guard let screen = screen, let window = window else { return }
        
        // 更新内容视图
        updateContent(contentType: contentType)
        
        // 设置窗口大小为屏幕大小
        window.setFrame(screen.frame, display: true)
        
        // 显示窗口
        window.orderFrontRegardless()
        
        print("🖼️ Overlay window shown with content: \(contentType)")
    }
    
    /// 隐藏遮罩
    func hide() {
        window?.orderOut(nil)
        print("🙈 Overlay window hidden")
    }
    
    // MARK: - Private Methods
    
    private func updateContent(contentType: ContentType) {
        let contentView: AnyView
        
        switch contentType {
        case .alert(let snoozeCount):
            // 显示提醒卡片，snoozeCount >= 1 时隐藏 Snooze 按钮
            let showSnooze = snoozeCount < 1
            contentView = AnyView(
                OverlayContentView(
                    content: .alert,
                    showSnoozeButton: showSnooze,
                    onMoveClicked: { [weak self] in
                        self?.onMoveClicked?()
                    },
                    onSnoozeClicked: { [weak self] in
                        self?.onSnoozeClicked?()
                    }
                )
            )
            
        case .breakTime(let remainingSeconds):
            // 显示休息倒计时卡片
            contentView = AnyView(
                OverlayContentView(
                    content: .breakTime(remainingSeconds: remainingSeconds),
                    onMoveClicked: {},
                    onSnoozeClicked: {}
                )
            )
            
        case .breakCompleted:
            // 显示完成卡片
            contentView = AnyView(
                OverlayContentView(
                    content: .breakCompleted,
                    onMoveClicked: {},
                    onSnoozeClicked: {}
                )
            )
        }
        
        let hostingView = NSHostingView(rootView: contentView)
        window?.contentView = hostingView
    }
}

// MARK: - Overlay Content View

private struct OverlayContentView: View {
    
    enum ContentMode {
        case alert
        case breakTime(remainingSeconds: Int)
        case breakCompleted
    }
    
    let content: ContentMode
    var showSnoozeButton: Bool = true
    var onMoveClicked: () -> Void
    var onSnoozeClicked: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 根据内容类型显示不同的卡片
            switch content {
            case .alert:
                AlertCardView(
                    onMoveClicked: onMoveClicked,
                    onSnoozeClicked: onSnoozeClicked,
                    showSnoozeButton: showSnoozeButton
                )
                
            case .breakTime(let remainingSeconds):
                BreakCardView(remainingSeconds: remainingSeconds)
                
            case .breakCompleted:
                CompletionCardView()
            }
        }
    }
}
