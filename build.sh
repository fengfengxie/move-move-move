#!/bin/bash

# Build script for MoveApp

set -e

echo "🏗️  Building MoveApp..."
echo ""

cd "$(dirname "$0")"

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
