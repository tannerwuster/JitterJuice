#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-"$ROOT_DIR/.derivedData"}"
CONFIGURATION="${CONFIGURATION:-Debug}"

APP_NAME="JitterJuice"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.tannerwuster.JitterJuice}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"

echo "Stopping $APP_NAME (if running)…"
if command -v osascript >/dev/null 2>&1; then
  osascript -e "try" \
            -e "  tell application id \"$APP_BUNDLE_ID\" to quit" \
            -e "end try" >/dev/null 2>&1 || true
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

echo "Building $APP_NAME ($CONFIGURATION)…"
if ! xcodebuild \
  -project "$ROOT_DIR/JitterJuice.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build; then
  cat <<'EOF' >&2

xcodebuild failed.

If you recently updated Xcode (or are missing Xcode components), run:
  xcodebuild -runFirstLaunch

If that still fails, reinstall Xcode and ensure:
  xcode-select -p
points at:
  /Applications/Xcode.app/Contents/Developer

EOF
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app not found at: $APP_PATH" >&2
  exit 1
fi

echo "Launching ${APP_PATH}…"
open "${APP_PATH}"

