import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    var activityMonitor: ActivityMonitor?
    var timerEngine: TimerEngine?
    
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // 使用 SF Symbols 图标
            button.image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: "Move")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        // 创建 Popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 250)
        popover?.behavior = .transient
        updatePopoverContent()
    }
    
    private func updatePopoverContent() {
        popover?.contentViewController = NSHostingController(
            rootView: MenuPopoverView(
                activityMonitor: activityMonitor,
                timerEngine: timerEngine
            )
        )
    }
    
    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        // 每次打开时更新内容以确保传递最新的 timerEngine
        if !popover.isShown {
            updatePopoverContent()
        }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
