#!/usr/bin/env bash
# Assembles a Debug .app so the `#if DEBUG` screenshot mode is compiled in.
# make-app.sh builds release, which strips it out.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/screenshots/.build/Tokengochi.app"
CONTENTS="$APP/Contents"

swift build --package-path "$ROOT"
BIN="$(swift build --package-path "$ROOT" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN/Tokengochi" "$CONTENTS/MacOS/Tokengochi"
[[ -f "$ROOT/AppIcon.icns" ]] && cp "$ROOT/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Tokengochi</string>
    <key>CFBundleDisplayName</key><string>Tokengochi</string>
    <key>CFBundleIdentifier</key><string>com.tokengochi.app.screenshots</string>
    <key>CFBundleExecutable</key><string>Tokengochi</string>
    <key>CFBundleVersion</key><string>0.0.0</string>
    <key>CFBundleShortVersionString</key><string>0.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "$APP"
