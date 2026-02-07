#!/bin/bash
set -e

APP_NAME="Snapdeck"
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
echo ""
echo "Next steps:"
echo "  1. Create a new release on GitHub: https://github.com/lonkarabhishek/Snapdeck/releases/new"
echo "  2. Upload $APP_NAME.zip as a release asset"
echo "  3. Tag it as v1.0.0 (or appropriate version)"
