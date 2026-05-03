#!/usr/bin/env bash
# Build MD Viewer in Release configuration and install it into /Applications.
# Usage: scripts/install.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MD Viewer"
SCHEME="$APP_NAME"
PROJECT="$PROJECT_DIR/$APP_NAME.xcodeproj"
DEST="/Applications/$APP_NAME.app"

cd "$PROJECT_DIR"

if pgrep -f "/Applications/$APP_NAME.app/Contents/MacOS/" >/dev/null 2>&1; then
    echo "Error: '$APP_NAME' is currently running. Quit it first." >&2
    exit 1
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Building $APP_NAME (Release)…"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    build >/dev/null

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
    echo "Error: build did not produce $BUILT_APP" >&2
    exit 1
fi

echo "Installing to $DEST…"
rm -rf "$DEST"
cp -R "$BUILT_APP" "$DEST"

# Clean up LaunchServices: unregister any stray copies of the bundle ID and
# re-register only the /Applications copy. Without this, macOS may launch an
# old build (e.g. from DerivedData or repo build/ folder) when the user opens
# the app or a Markdown file.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
BUNDLE_ID="com.quentin.MDViewer"
echo "Cleaning LaunchServices registrations…"
"$LSREGISTER" -dump 2>/dev/null \
    | awk '/^[[:space:]]*path:/ {p=$0} /'"$BUNDLE_ID"'/ {print p}' \
    | sed -E 's/^[[:space:]]*path:[[:space:]]+//; s/[[:space:]]+\(0x[0-9a-f]+\)$//' \
    | grep -v "^$DEST\$" \
    | while IFS= read -r stale; do
        [ -n "$stale" ] && "$LSREGISTER" -u "$stale" 2>/dev/null || true
    done
"$LSREGISTER" -f "$DEST"

echo "Done. Installed $APP_NAME from $BUILT_APP."
