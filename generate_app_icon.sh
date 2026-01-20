#!/bin/bash
# 生成更好的App图标 - 与menubar风格一致

set -e

cd "$(dirname "$0")"
ICON_DIR="Resources/Assets.xcassets/AppIcon.appiconset"

echo "🎨 生成新的App图标..."

# 创建一个更好的SVG图标（圆角、渐变背景、走路图标）
cat > temp_icon.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- 渐变背景 -->
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#00D4FF;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#00A8E8;stop-opacity:1" />
    </linearGradient>
    
    <!-- 圆角遮罩 - macOS标准圆角 -->
    <clipPath id="roundedCorner">
      <rect width="1024" height="1024" rx="226" ry="226"/>
    </clipPath>
  </defs>
  
  <!-- 背景 -->
  <rect width="1024" height="1024" rx="226" ry="226" fill="url(#bg)"/>
  
  <!-- 走路的人图标 - 使用简单的几何图形 -->
  <g transform="translate(512, 512)" clip-path="url(#roundedCorner)">
    <!-- 人物剪影 -->
    <g transform="translate(-150, -200) scale(15)">
      <!-- 头部 -->
      <circle cx="10" cy="0" r="4" fill="white"/>
      
      <!-- 身体 -->
      <line x1="10" y1="4" x2="10" y2="16" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
      
      <!-- 左臂（向后） -->
      <line x1="10" y1="7" x2="5" y2="12" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
      
      <!-- 右臂（向前） -->
      <line x1="10" y1="7" x2="15" y2="10" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
      
      <!-- 左腿（抬起向前） -->
      <line x1="10" y1="16" x2="14" y2="25" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
      
      <!-- 右腿（向后支撑） -->
      <line x1="10" y1="16" x2="7" y2="24" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
    </g>
    
    <!-- 运动线条效果 -->
    <g opacity="0.3">
      <line x1="-180" y1="-50" x2="-140" y2="-50" stroke="white" stroke-width="8" stroke-linecap="round"/>
      <line x1="-180" y1="0" x2="-130" y2="0" stroke="white" stroke-width="8" stroke-linecap="round"/>
      <line x1="-180" y1="50" x2="-140" y2="50" stroke="white" stroke-width="8" stroke-linecap="round"/>
    </g>
  </g>
</svg>
EOF

# 使用sips转换SVG为PNG
if command -v rsvg-convert &> /dev/null; then
    echo "  使用 rsvg-convert..."
    rsvg-convert -w 1024 -h 1024 temp_icon.svg > temp_icon_1024.png
elif command -v qlmanage &> /dev/null; then
    echo "  使用 qlmanage..."
    qlmanage -t -s 1024 -o . temp_icon.svg 2>/dev/null
    [ -f temp_icon.svg.png ] && mv temp_icon.svg.png temp_icon_1024.png
fi

# 如果还是没有生成，使用sips创建一个纯色图标作为备用
if [ ! -f temp_icon_1024.png ]; then
    echo "  ⚠️ 无法转换SVG，使用备用方案..."
    # 创建一个简单的蓝色渐变图标
    sips -z 1024 1024 temp_icon.svg --out temp_icon_1024.png 2>/dev/null || {
        # 最后的备用方案：创建一个纯色方块
        python3 -c "
from PIL import Image, ImageDraw
import sys

try:
    # 创建带圆角的渐变图标
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制圆角矩形背景
    corner_radius = 226  # macOS标准圆角
    
    # 渐变背景
    for y in range(size):
        r = int(0 + (y / size) * 0)
        g = int(212 + (y / size) * (168 - 212))
        b = int(255 + (y / size) * (232 - 255))
        for x in range(size):
            # 检查是否在圆角内
            in_corner = True
            if x < corner_radius and y < corner_radius:
                in_corner = (x - corner_radius)**2 + (y - corner_radius)**2 < corner_radius**2
            elif x > size - corner_radius and y < corner_radius:
                in_corner = (x - (size - corner_radius))**2 + (y - corner_radius)**2 < corner_radius**2
            elif x < corner_radius and y > size - corner_radius:
                in_corner = (x - corner_radius)**2 + (y - (size - corner_radius))**2 < corner_radius**2
            elif x > size - corner_radius and y > size - corner_radius:
                in_corner = (x - (size - corner_radius))**2 + (y - (size - corner_radius))**2 < corner_radius**2
            
            if in_corner:
                img.putpixel((x, y), (r, g, b, 255))
    
    # 绘制简单的走路图标
    # 使用白色线条绘制
    draw.ellipse([462, 312, 562, 412], fill='white')  # 头
    draw.line([(512, 412), (512, 612)], fill='white', width=40)  # 身体
    draw.line([(512, 462), (412, 512)], fill='white', width=35)  # 左臂
    draw.line([(512, 462), (612, 512)], fill='white', width=35)  # 右臂
    draw.line([(512, 612), (562, 762)], fill='white', width=35)  # 左腿
    draw.line([(512, 612), (462, 762)], fill='white', width=35)  # 右腿
    
    img.save('temp_icon_1024.png')
    print('✓ 图标生成成功（Python方案）')
except ImportError:
    print('✗ 需要安装 Pillow: pip3 install pillow', file=sys.stderr)
    sys.exit(1)
" || echo "  ⚠️ 需要手动创建图标"
    }
fi

if [ ! -f temp_icon_1024.png ]; then
    echo "❌ 无法生成图标，请检查依赖"
    exit 1
fi

# 生成所有需要的尺寸
echo "  生成各种尺寸..."
mkdir -p "$ICON_DIR/temp.iconset"

sips -z 16 16 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_16x16.png" 2>/dev/null
sips -z 32 32 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_16x16@2x.png" 2>/dev/null
sips -z 32 32 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_32x32.png" 2>/dev/null
sips -z 64 64 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_32x32@2x.png" 2>/dev/null
sips -z 128 128 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_128x128.png" 2>/dev/null
sips -z 256 256 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_128x128@2x.png" 2>/dev/null
sips -z 256 256 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_256x256.png" 2>/dev/null
sips -z 512 512 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_256x256@2x.png" 2>/dev/null
sips -z 512 512 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_512x512.png" 2>/dev/null
sips -z 1024 1024 temp_icon_1024.png --out "$ICON_DIR/temp.iconset/icon_512x512@2x.png" 2>/dev/null

# 使用iconutil生成.icns文件
echo "  生成 .icns 文件..."
iconutil -c icns "$ICON_DIR/temp.iconset" -o "Resources/Assets.xcassets/AppIcon.icns"

# 清理临时文件
rm -rf "$ICON_DIR/temp.iconset"
rm -f temp_icon.svg temp_icon_1024.png temp_icon.svg.png

echo "✅ App图标生成完成！"
echo "   位置: Resources/Assets.xcassets/AppIcon.icns"
ls -lh Resources/Assets.xcassets/AppIcon.icns
