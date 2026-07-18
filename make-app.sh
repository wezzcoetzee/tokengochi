#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
BUNDLE_ID="com.tokengochi.app"
APP_NAME="Tokengochi"

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/.build/release"
DIST="$ROOT/dist"

# Assemble/sign outside iCloud Drive: the iCloud file provider attaches
# com.apple.fileprovider.fpfs#P / com.apple.FinderInfo xattrs that cannot be
# stripped, and codesign rejects them ("resource fork … detritus not allowed").
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APP="$WORK/$APP_NAME.app"
CONTENTS="$APP/Contents"

echo "▸ Building release binaries…"
swift build -c release

echo "▸ Assembling $APP_NAME.app…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Helpers" "$CONTENTS/Library/LaunchAgents"

cp "$BUILD/$APP_NAME"        "$CONTENTS/MacOS/$APP_NAME"
cp "$BUILD/TokengochiWriter" "$CONTENTS/Helpers/TokengochiWriter"
cp "$BUILD/TokengochiPoller" "$CONTENTS/Helpers/TokengochiPoller"
cp "$ROOT/com.tokengochi.poller.agent.plist" "$CONTENTS/Library/LaunchAgents/com.tokengochi.poller.plist"

if [[ ! -f "$ROOT/AppIcon.icns" && -f "$ROOT/AppIcon.png" ]]; then
  echo "▸ Generating AppIcon.icns from AppIcon.png…"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for size in 16 32 64 128 256 512 1024; do
    sips -z "$size" "$size" "$ROOT/AppIcon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  done
  cp "$ICONSET/icon_32x32.png"     "$ICONSET/icon_16x16@2x.png"
  cp "$ICONSET/icon_64x64.png"     "$ICONSET/icon_32x32@2x.png"
  cp "$ICONSET/icon_256x256.png"   "$ICONSET/icon_128x128@2x.png"
  cp "$ICONSET/icon_512x512.png"   "$ICONSET/icon_256x256@2x.png"
  cp "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
  rm "$ICONSET/icon_64x64.png" "$ICONSET/icon_1024x1024.png"
  iconutil -c icns "$ICONSET" -o "$ROOT/AppIcon.icns"
fi

if [[ -f "$ROOT/AppIcon.icns" ]]; then
  cp "$ROOT/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
  ICON_KEY='<key>CFBundleIconFile</key><string>AppIcon</string>'
else
  ICON_KEY=''
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    $ICON_KEY
</dict>
</plist>
PLIST

echo "▸ Ad-hoc signing…"
codesign --force --sign - "$CONTENTS/Helpers/TokengochiWriter"
codesign --force --sign - "$CONTENTS/Helpers/TokengochiPoller"
codesign --force --sign - "$APP"

mkdir -p "$DIST"
rm -rf "$DIST/$APP_NAME.app"
ditto "$APP" "$DIST/$APP_NAME.app"

echo "▸ Zipping…"
ZIP="$DIST/$APP_NAME-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Building DMG…"
DMG="$DIST/$APP_NAME-$VERSION.dmg"
STAGE="$(mktemp -d)/$APP_NAME"
rm -f "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov "$DMG" >/dev/null
rm -rf "$STAGE"

echo "✓ Done: $ZIP"
echo "✓ Done: $DMG"
