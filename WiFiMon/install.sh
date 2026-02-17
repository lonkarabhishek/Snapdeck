#!/bin/bash
set -e

APP_NAME="WiFiMon"
APP_PATH="/Applications/$APP_NAME.app"
ZIP_URL="https://github.com/lonkarabhishek/Snapdeck/releases/latest/download/WiFiMon.zip"
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
