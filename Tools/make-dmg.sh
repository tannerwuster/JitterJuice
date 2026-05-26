#!/usr/bin/env bash
# Build a drag-to-Applications DMG: includes JitterJuice.app and a symlink to /Applications.
set -euo pipefail

usage() {
  echo "Usage: $0 path/to/JitterJuice.app [output.dmg]" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage
APP="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
OUT="${2:-JitterJuice.dmg}"

[[ -d "$APP" ]] || { echo "Not a bundle: $APP" >&2; exit 1; }

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jitterjuice-dmg.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

cp -R "$APP" "$STAGE/"
# Finder shows this as “Applications” so users can drag the app onto it.
ln -sf /Applications "$STAGE/Applications"

VOLNAME="JitterJuice"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDZO -fs HFS+ "$OUT"

echo "Created $(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
