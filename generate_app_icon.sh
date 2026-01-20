#!/bin/bash
# 基于SF Symbol figure.walk生成App图标 - 使用Swift

set -e

cd "$(dirname "$0")"
ICON_DIR="Resources/Assets.xcassets/AppIcon.appiconset"

echo "🎨 生成App图标（基于SF Symbol figure.walk）..."

# 使用Swift生成图标
swift - <<'SWIFT_SCRIPT'
import AppKit
import CoreGraphics

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    let context = NSGraphicsContext.current!.cgContext
    
    // macOS标准圆角比例
    let cornerRadius = size * 0.2207
    
    // 绘制深色背景
    context.setFillColor(CGColor(red: 0.176, green: 0.176, blue: 0.188, alpha: 1.0))
    let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                      cornerWidth: cornerRadius,
                      cornerHeight: cornerRadius,
                      transform: nil)
    context.addPath(path)
    context.fillPath()
    
    // 使用SF Symbol绘制figure.walk
    if let symbol = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil) {
        let symbolSize = size * 0.55
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
        let configuredSymbol = symbol.withSymbolConfiguration(symbolConfig)
        
        // 设置白色
        let whiteSymbol = NSImage(size: NSSize(width: symbolSize, height: symbolSize))
        whiteSymbol.lockFocus()
        NSColor.white.set()
        configuredSymbol?.draw(in: NSRect(x: 0, y: 0, width: symbolSize, height: symbolSize))
        whiteSymbol.unlockFocus()
        
        // 居中绘制
        let x = (size - symbolSize) / 2
        let y = (size - symbolSize) / 2
        whiteSymbol.draw(in: NSRect(x: x, y: y, width: symbolSize, height: symbolSize))
    }
    
    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return
    }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

// 生成所有需要的尺寸
let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let iconsetPath = "Resources/Assets.xcassets/AppIcon.appiconset/temp.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

print("  生成各种尺寸...")
for (filename, size) in sizes {
    let icon = createIcon(size: size)
    saveImage(icon, to: "\(iconsetPath)/\(filename)")
}

// 保存1024版本用于验证
let icon1024 = createIcon(size: 1024)
saveImage(icon1024, to: "temp_icon_1024.png")

print("✓ PNG文件生成完成")
SWIFT_SCRIPT

# 检查是否成功生成
if [ ! -f temp_icon_1024.png ]; then
    echo "❌ 图标生成失败"
    exit 1
fi

# 使用iconutil生成.icns文件
echo "  生成 .icns 文件..."
iconutil -c icns "$ICON_DIR/temp.iconset" -o "Resources/Assets.xcassets/AppIcon.icns"

# 清理临时文件
rm -rf "$ICON_DIR/temp.iconset"
rm -f temp_icon_1024.png

echo "✅ App图标生成完成！"
echo "   位置: Resources/Assets.xcassets/AppIcon.icns"
ls -lh Resources/Assets.xcassets/AppIcon.icns
