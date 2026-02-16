#!/bin/bash
set -e

APP_NAME="CleanDock"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$BUILD_DIR/Sources"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "==> Cleaning previous build..."
rm -rf "$APP_BUNDLE"

echo "==> Creating app bundle structure..."
mkdir -p "$MACOS_DIR"

echo "==> Compiling..."
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -target "$(uname -m)-apple-macosx13.0" \
    -framework AppKit \
    -framework SwiftUI \
    "$SOURCES_DIR/DownloadItem.swift" \
    "$SOURCES_DIR/DownloadStore.swift" \
    "$SOURCES_DIR/DownloadWatcher.swift" \
    "$SOURCES_DIR/DownloadRow.swift" \
    "$SOURCES_DIR/MenuBarView.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/main.swift"

echo "==> Copying Info.plist..."
cp "$BUILD_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "==> Build complete: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "  or:    $MACOS_DIR/$APP_NAME"
