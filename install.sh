#!/bin/bash
set -e

APP_NAME="Snapdeck"
APP_PATH="/Applications/$APP_NAME.app"
ZIP_URL="https://github.com/lonkarabhishek/Snapdeck/releases/latest/download/Snapdeck.zip"
TMP_DIR=$(mktemp -d)

echo ""
echo "==> Installing $APP_NAME..."
echo ""

# Download latest release
echo "  Downloading..."
curl -sL "$ZIP_URL" -o "$TMP_DIR/$APP_NAME.zip"

# Unzip
echo "  Extracting..."
unzip -q "$TMP_DIR/$APP_NAME.zip" -d "$TMP_DIR"

# Move to Applications
echo "  Moving to /Applications..."
rm -rf "$APP_PATH"
mv "$TMP_DIR/$APP_NAME.app" "$APP_PATH"

# Remove quarantine flag so macOS doesn't block it
echo "  Removing macOS quarantine flag..."
xattr -cr "$APP_PATH"

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "==> $APP_NAME installed successfully!"
echo "  Opening $APP_NAME..."
echo ""

open "$APP_PATH"
