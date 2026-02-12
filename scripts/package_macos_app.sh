#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-SwiftADBTool}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-SwiftADBTool}"
BUNDLE_ID="${BUNDLE_ID:-com.swiftadbtool.app}"
APP_VERSION="${APP_VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
CONFIGURATION="${CONFIGURATION:-release}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

RESOURCE_DIR="$ROOT_DIR/Sources/SwiftADBTool/Resources"
RESOURCE_ICON="$RESOURCE_DIR/AppIcon.icns"

if [[ ! -d "$RESOURCE_DIR" ]]; then
  echo "[ERROR] Missing resources directory: $RESOURCE_DIR"
  exit 1
fi

if [[ ! -f "$RESOURCE_ICON" ]]; then
  echo "[ERROR] Missing icon: $RESOURCE_ICON"
  exit 1
fi

echo "[1/4] Building $EXECUTABLE_NAME ($CONFIGURATION)..."
if ! swift build -c "$CONFIGURATION" >/dev/null; then
  echo "[WARN] Initial build failed. Cleaning .build and retrying once..."
  rm -rf "$ROOT_DIR/.build"
  swift build -c "$CONFIGURATION" >/dev/null
fi
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BIN_PATH="$BIN_DIR/$EXECUTABLE_NAME"

if [[ ! -f "$BIN_PATH" ]]; then
  CANDIDATE_1="$ROOT_DIR/.build/$CONFIGURATION/$EXECUTABLE_NAME"
  CANDIDATE_2="$ROOT_DIR/.build/arm64-apple-macosx/$CONFIGURATION/$EXECUTABLE_NAME"
  if [[ -f "$CANDIDATE_1" ]]; then
    BIN_PATH="$CANDIDATE_1"
  elif [[ -f "$CANDIDATE_2" ]]; then
    BIN_PATH="$CANDIDATE_2"
  else
    FOUND_PATH="$(find "$ROOT_DIR/.build" -type f -path "*/$CONFIGURATION/$EXECUTABLE_NAME" | head -n 1 || true)"
    if [[ -n "$FOUND_PATH" ]]; then
      BIN_PATH="$FOUND_PATH"
    fi
  fi
fi

if [[ ! -f "$BIN_PATH" ]]; then
  echo "[ERROR] Binary not found: $BIN_PATH"
  exit 1
fi

APP_DIR="$OUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RES_DIR="$CONTENTS_DIR/Resources"
PLIST_PATH="$CONTENTS_DIR/Info.plist"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "[2/4] Assembling app bundle..."
cp "$BIN_PATH" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"
cp -R "$RESOURCE_DIR/." "$RES_DIR/"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "[3/4] Signing app with identity: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR"
else
  echo "[3/4] Signing app ad-hoc (no SIGN_IDENTITY provided)."
  codesign --force --deep --sign - "$APP_DIR"
fi

ZIP_PATH="$OUT_DIR/${APP_NAME}-${APP_VERSION}-macOS.zip"
rm -f "$ZIP_PATH"
echo "[4/4] Creating archive: $ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo
echo "Done."
echo "App : $APP_DIR"
echo "Zip : $ZIP_PATH"
