import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    var activityMonitor: ActivityMonitor?
    var timerEngine: TimerEngine?
    var settingsStore: SettingsStore?
    
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
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
        popover?.contentSize = NSSize(width: 320, height: 250)
        popover?.behavior = .transient
        popover?.delegate = self
        updatePopoverContent()
    }
    
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover()
            }
        }
    }
    
    private func updatePopoverContent() {
        guard let settings = settingsStore else { return }
        popover?.contentViewController = NSHostingController(
            rootView: MenuPopoverView(
                activityMonitor: activityMonitor,
                timerEngine: timerEngine,
                settingsStore: settings
            )
        )
    }
    
    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            // 每次打开时更新内容以确保传递最新的 timerEngine
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    private func closePopover() {
        popover?.performClose(nil)
        eventMonitor?.stop()
    }
}

// MARK: - NSPopoverDelegate

extension MenuBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        eventMonitor?.stop()
    }
}

// MARK: - Event Monitor Helper

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
