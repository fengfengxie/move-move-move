import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化 Menu Bar Controller
        menuBarController = MenuBarController()
        
        // 隐藏主窗口（如果有）
        NSApplication.shared.setActivationPolicy(.accessory)
        
        print("✅ MoveApp launched successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 MoveApp terminated")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
