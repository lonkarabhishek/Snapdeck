#!/bin/bash
set -e

APP_NAME="DropShelf"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
ZIP_FILE="$BUILD_DIR/$APP_NAME.zip"

echo "==> Building app..."
"$BUILD_DIR/build.sh"

echo "==> Packaging $APP_NAME.zip..."
rm -f "$ZIP_FILE"
cd "$BUILD_DIR"
zip -r -q "$ZIP_FILE" "$APP_NAME.app"

SIZE=$(du -h "$ZIP_FILE" | cut -f1 | xargs)
echo ""
echo "==> Release package ready: $ZIP_FILE ($SIZE)"
