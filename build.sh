#!/bin/bash

# Build script for MoveApp
# Usage:
#   ./build.sh          - Quick development build
#   ./build.sh release  - Production release build with .app bundle

set -e

cd "$(dirname "$0")"

MODE="${1:-debug}"

if [ "$MODE" = "release" ] || [ "$MODE" = "package" ]; then
    echo "📦 Building MoveApp for Release..."
    echo ""
    
    # Build configuration
    APP_NAME="Move!Move!Move!"
    BUNDLE_ID="com.fengfengxie.MoveApp"
    BUILD_DIR=".build/release"
    APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
    
    # Clean previous build
    echo "🧹 Cleaning previous build..."
    swift package clean
    rm -rf "$APP_BUNDLE"
    
    # Build release binary
    echo "⚙️  Building release binary..."
    swift build -c release
    
    # Create app bundle structure
    echo "📦 Creating app bundle..."
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    
    # Copy binary
    cp "$BUILD_DIR/MoveApp" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Copy resources
    if [ -f "Resources/Assets.xcassets/AppIcon.icns" ]; then
        cp "Resources/Assets.xcassets/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
        echo "✓ App icon copied"
    fi
    
    # Create Info.plist
    cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 fengfengxie. All rights reserved.</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>MoveApp needs permission to lock your screen after breaks for privacy.</string>
</dict>
</plist>
EOF

    # Optional code signing
    # Usage:
    #   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh release
    #   CODESIGN_ADHOC=1 ./build.sh release
    if [ -n "$CODESIGN_IDENTITY" ]; then
        echo "🔏 Code signing with identity: $CODESIGN_IDENTITY"
        codesign --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
    elif [ "$CODESIGN_ADHOC" = "1" ]; then
        echo "🔏 Ad-hoc code signing enabled"
        codesign --force --sign - "$APP_BUNDLE"
    fi

    # Optional zip packaging for distribution
    # Usage: PACKAGE_ZIP=1 ./build.sh release
    if [ "$PACKAGE_ZIP" = "1" ]; then
        ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
        echo "📦 Creating zip package: $ZIP_PATH"
        ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
    fi
    
    echo ""
    echo "✅ Release build successful!"
    echo ""
    echo "📦 App bundle created at:"
    echo "   $APP_BUNDLE"
    echo ""
    echo "To install:"
    echo "   cp -R '$APP_BUNDLE' /Applications/"
    echo ""
    echo "To run directly:"
    echo "   open '$APP_BUNDLE'"
    
else
    # Development build
    echo "🏗️  Building MoveApp (Development)..."
    echo ""
    
    # Clean previous build
    echo "🧹 Cleaning previous build..."
    swift package clean
    
    # Build the project
    echo "⚙️  Building..."
    swift build
    
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "To run the app:"
    echo "  swift run MoveApp"
    echo ""
    echo "Or open in Xcode:"
    echo "  open Package.swift"
    echo ""
    echo "To build for release:"
    echo "  ./build.sh release"
fi
