#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/build/DevBox Manager.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/DevBoxManager"

echo "Building DevBox Manager…"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Generate icon into build
echo "Generating icon…"
python3 "$SCRIPT_DIR/generate_icon.py" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Compile
swiftc \
    -O \
    -whole-module-optimization \
    -target "$(uname -m)-apple-macosx12.0" \
    -o "$EXECUTABLE" \
    "$SCRIPT_DIR/Sources/main.swift"

echo "✅ Built successfully: $APP_BUNDLE"
echo ""
echo "To install: cp -r \"$APP_BUNDLE\" /Applications/"
