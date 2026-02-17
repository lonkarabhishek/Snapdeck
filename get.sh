#!/bin/bash
set -e

APPS="Snapdeck KleepMe QuickScrap TextGrab CleanDock DropShelf"
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
    echo ""
    exit 1
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
    echo "Available: $APPS"
    exit 1
fi

APP_PATH="/Applications/$APP_NAME.app"
ZIP_URL="https://github.com/lonkarabhishek/Snapdeck/releases/latest/download/$APP_NAME.zip"
TMP_DIR=$(mktemp -d)

echo ""
echo "==> Installing $APP_NAME..."
echo ""

echo "  Downloading..."
curl -sL "$ZIP_URL" -o "$TMP_DIR/$APP_NAME.zip"

echo "  Extracting..."
unzip -q "$TMP_DIR/$APP_NAME.zip" -d "$TMP_DIR"

echo "  Moving to /Applications..."
rm -rf "$APP_PATH"
mv "$TMP_DIR/$APP_NAME.app" "$APP_PATH"

echo "  Removing macOS quarantine flag..."
xattr -cr "$APP_PATH"

rm -rf "$TMP_DIR"

echo ""
echo "==> $APP_NAME installed successfully!"
echo "  Opening $APP_NAME..."
echo ""

open "$APP_PATH"
