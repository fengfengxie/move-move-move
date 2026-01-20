# Move!Move!Move! - 快速开发指南

## 📁 项目结构

```
MoveApp/
├── App/                        # 应用程序入口
│   ├── MoveApp.swift          # App 主入口
│   └── AppDelegate.swift      # 应用生命周期管理
│
├── Core/                       # 核心业务逻辑
│   ├── TimerEngine.swift      # 计时引擎（状态机）
│   ├── ActivityMonitor.swift  # 用户活跃监测（IOKit）
│   └── SettingsStore.swift    # 设置存储（UserDefaults）
│
├── UI/                         # 用户界面
│   ├── MenuBar/               # 菜单栏组件
│   │   ├── MenuBarController.swift   # 状态栏控制器
│   │   └── MenuPopoverView.swift     # 弹出面板视图
│   │
│   └── Overlay/               # 全屏遮罩组件
│       ├── OverlayWindowController.swift  # 遮罩窗口控制器
│       ├── AlertCardView.swift            # 提醒卡片
│       └── BreakCardView.swift            # 休息倒计时卡片
│
├── Resources/                  # 资源文件
│   └── Assets.xcassets        # 图标、图片等
│
├── Package.swift               # Swift Package Manager 配置
├── Info.plist                  # App 配置（LSUIElement = YES）
├── README.md                   # 项目说明
└── build.sh                    # 快速构建脚本
```

## 🚀 快速开始

### 方式 1: 使用 Xcode（推荐）

```bash
cd /Users/xiefeng/Developer/playground/MoveApp
open Package.swift
```

然后在 Xcode 中：
1. 等待依赖解析完成
2. 选择 `MoveApp` scheme
3. 按 `Cmd + R` 运行

### 方式 2: 命令行构建

```bash
cd /Users/xiefeng/Developer/playground/MoveApp

# 构建
swift build

# 运行
swift run MoveApp
```

### 方式 3: 使用构建脚本

```bash
cd /Users/xiefeng/Developer/playground/MoveApp
./build.sh
swift run MoveApp
```

## 🏗️ Phase 1 完成内容

### ✅ 已实现

1. **项目框架**
   - Swift Package Manager 项目结构
   - Menu Bar App 配置（无 Dock 图标）
   - 基础文件组织

2. **Menu Bar 功能**
   - NSStatusItem 状态栏图标（🚶 figure.walk）
   - NSPopover 弹出面板
   - 点击显示/隐藏功能
   - 基础 UI 布局

3. **核心模块骨架**
   - `TimerEngine`: 状态机定义、计时逻辑框架
   - `ActivityMonitor`: IOKit 集成、系统事件监听
   - `SettingsStore`: 设置持久化、每日统计

4. **Overlay UI 组件**
   - `OverlayWindowController`: 全屏遮罩窗口
   - `AlertCardView`: "MOVE! MOVE! MOVE!" 提醒卡片
   - `BreakCardView`: 休息倒计时卡片

5. **构建系统**
   - Package.swift 配置完成
   - 编译通过 ✅
   - Info.plist 正确配置

## 🎯 下一步：Phase 2

Phase 2 将专注于 **活跃状态监测**：

1. 完善 `ActivityMonitor.getSystemIdleSeconds()` 实现
2. 测试 idle 时间检测准确性
3. 验证系统事件通知（睡眠、唤醒、锁屏）
4. 将 ActivityMonitor 与 TimerEngine 集成
5. 实现自动暂停/恢复逻辑

## 📝 开发提示

### 调试菜单栏应用

由于 `LSUIElement = YES`，应用不会出现在 Dock 中。要调试：

1. **查看日志**: 在 Console.app 中过滤 "MoveApp"
2. **强制退出**: 
   ```bash
   pkill -f MoveApp
   ```
3. **临时显示 Dock**: 在开发时可以暂时注释掉 `LSUIElement`

### IOKit 权限

`getSystemIdleSeconds()` 使用 IOKit 读取 `HIDIdleTime`，**不需要** Accessibility 权限。

### SwiftUI Previews

AlertCardView 和 BreakCardView 都有 SwiftUI Preview，可以在 Xcode 中快速预览：

```swift
#Preview("Alert Card - With Snooze") {
    // ...
}
```

### 状态机调试

TimerEngine 的状态机在每次状态变化时都会打印日志：

```
⏱️ TimerEngine initialized
▶️ TimerEngine started
⏰ Alert triggered!
😴 Snoozing until 2026-01-20 15:30:00 +0000, count: 1
🧘 Break started: 60s
✅ Break completed! Total today: 1
🔄 Cycle reset
```

## 🔍 代码导航

### 关键类和协议

| 类名 | 职责 | 位置 |
|------|------|------|
| `MoveApp` | App 入口 | App/MoveApp.swift |
| `AppDelegate` | 应用生命周期 | App/AppDelegate.swift |
| `MenuBarController` | 菜单栏控制 | UI/MenuBar/MenuBarController.swift |
| `TimerEngine` | 核心计时逻辑 | Core/TimerEngine.swift |
| `ActivityMonitor` | 活跃监测 | Core/ActivityMonitor.swift |
| `SettingsStore` | 设置存储 | Core/SettingsStore.swift |
| `OverlayWindowController` | 遮罩窗口 | UI/Overlay/OverlayWindowController.swift |

### 关键 SF Symbols 使用

- 菜单栏图标: `figure.walk`
- 设置图标: `gearshape`
- 退出图标: `xmark.circle`

## 📊 Phase 进度

| Phase | 状态 | 预计时间 | 实际时间 |
|-------|------|----------|----------|
| Phase 1: 项目基础架构 | ✅ 完成 | 1-2h | ~1.5h |
| Phase 2: 活跃状态监测 | 🔜 待开始 | 1-2h | - |
| Phase 3: 核心计时引擎 | ⏳ 未开始 | 2-3h | - |
| Phase 4: Overlay 提醒窗口 | ⏳ 未开始 | 2-3h | - |
| Phase 5: Snooze 机制 | ⏳ 未开始 | 1h | - |
| Phase 6: Break 倒计时 | ⏳ 未开始 | 1-2h | - |
| Phase 7: Menu Popover 完善 | ⏳ 未开始 | 1-2h | - |
| Phase 8: 设置与持久化 | ⏳ 未开始 | 1-2h | - |
| Phase 9: 测试与优化 | ⏳ 未开始 | 1-2h | - |
| Phase 10: 打包发布 | ⏳ 未开始 | 1h | - |

## 🐛 已知问题

无（Phase 1 已全部解决）

## 💡 技术决策记录

1. **为什么使用 Swift Package Manager 而不是 Xcode Project?**
   - 更简洁的项目结构
   - 更好的版本控制（无 .xcodeproj 冲突）
   - 命令行构建更方便

2. **为什么使用 IOKit 而不是 Accessibility API?**
   - 不需要用户授予 Accessibility 权限
   - 更轻量级，性能更好
   - 足够满足 idle 时间检测需求

3. **为什么混合使用 SwiftUI 和 AppKit?**
   - SwiftUI 用于内容视图（快速开发、现代化）
   - AppKit 用于窗口管理（NSStatusItem、NSPanel、window level 控制）
   - 最佳实践：NSHostingView 桥接两者

---

**准备好开始 Phase 2 了吗？** 🚀
