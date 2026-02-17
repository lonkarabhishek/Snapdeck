#!/bin/bash
set -e

APPS="Snapdeck KleepMe QuickScrap TextGrab CleanDock DropShelf WiFiMon"
APP_NAME="$1"

if [ -z "$APP_NAME" ]; then
    echo ""
    echo "Usage: curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s <app>"
    echo ""
    echo "Available apps:"
    echo "  Snapdeck   — Screenshot manager"
    echo "  KleepMe    — Clipboard history"
    echo "  QuickScrap — Menu bar scratchpad"
    echo "  TextGrab   — Screen OCR text extraction"
    echo "  CleanDock  — Downloads folder cleaner"
    echo "  DropShelf  — Drag & drop parking shelf"
    echo "  WiFiMon    — Wi-Fi speed & ping monitor"
    echo "  all        — Install everything"
    echo ""
    exit 1
fi

install_app() {
    local name="$1"
    local APP_PATH="/Applications/$name.app"
    local ZIP_URL="https://github.com/lonkarabhishek/Snapdeck/releases/latest/download/$name.zip"
    local TMP_DIR=$(mktemp -d)

    echo ""
    echo "==> Installing $name..."

    echo "  Downloading..."
    curl -sL "$ZIP_URL" -o "$TMP_DIR/$name.zip"

    echo "  Extracting..."
    unzip -q "$TMP_DIR/$name.zip" -d "$TMP_DIR"

    echo "  Moving to /Applications..."
    rm -rf "$APP_PATH"
    mv "$TMP_DIR/$name.app" "$APP_PATH"

    echo "  Removing macOS quarantine flag..."
    xattr -cr "$APP_PATH"

    rm -rf "$TMP_DIR"

    echo "  $name installed!"
    open "$APP_PATH"
}

# Install all apps
if [ "$APP_NAME" = "all" ]; then
    echo ""
    echo "==> Installing all Barkit apps..."
    for app in $APPS; do
        install_app "$app"
    done
    echo ""
    echo "==> All apps installed successfully!"
    exit 0
fi

# Validate app name
VALID=false
for app in $APPS; do
    if [ "$app" = "$APP_NAME" ]; then
        VALID=true
        break
    fi
done

if [ "$VALID" = false ]; then
    echo "Unknown app: $APP_NAME"
    echo "Available: $APPS all"
    exit 1
fi

install_app "$APP_NAME"
echo ""
echo "==> $APP_NAME installed successfully!"
echo ""
