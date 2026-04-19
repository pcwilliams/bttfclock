#!/usr/bin/env bash
#
# Build a Release configuration of bttfclock for native macOS, copy it
# into /Applications (replacing any prior install), and launch it.
#
# Usage:  ./install-mac.sh
#
# Notes:
# - Uses -derivedDataPath build/ so the Release .app lands in a
#   predictable spot next to the project, independent of Xcode's global
#   DerivedData.
# - Kills any running instance first so the copy doesn't hit "file
#   busy". Deletes the SwiftUI-autosaved window frame so the new build
#   opens at its current .defaultSize instead of whatever the user last
#   dragged it to.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

SCHEME="bttfclock"
BUNDLE_ID="com.pwilliams.bttfclock"
DERIVED="$PROJECT_DIR/build"
APP_SRC="$DERIVED/Build/Products/Release/${SCHEME}.app"
APP_DST="/Applications/${SCHEME}.app"

echo "==> Building Release for macOS..."
xcodebuild \
    -project "${SCHEME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "${DERIVED}" \
    -allowProvisioningUpdates \
    build \
    | xcbeautify 2>/dev/null \
    || xcodebuild \
        -project "${SCHEME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -destination "platform=macOS" \
        -derivedDataPath "${DERIVED}" \
        -allowProvisioningUpdates \
        build \
        | tail -20

if [[ ! -d "${APP_SRC}" ]]; then
    echo "!! Build didn't produce ${APP_SRC}" >&2
    exit 1
fi

echo "==> Quitting any running instance..."
killall "${SCHEME}" 2>/dev/null || true
sleep 0.3

echo "==> Clearing saved window state..."
defaults delete "${BUNDLE_ID}" 2>/dev/null || true
rm -rf "${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState" 2>/dev/null || true

echo "==> Installing to ${APP_DST}..."
rm -rf "${APP_DST}"
cp -R "${APP_SRC}" "${APP_DST}"

echo "==> Launching..."
open "${APP_DST}"

echo "==> Done."
