#!/bin/bash
# Construit et lance la sonde iOS du lot 0 (point 5 : géométrie) sur un simulateur.
#   usage : native/probe/ios/build.sh [UDID]
# Sans UDID, prend le premier appareil démarré.
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/../../.." && pwd)"
SORTIE="/tmp/ac-ios-probe"
APP="$SORTIE/ACProbe.app"
UDID="${1:-$(xcrun simctl list devices booted -j | python3 -c 'import json,sys;d=json.load(sys.stdin)["devices"];print(next(x["udid"] for v in d.values() for x in v))')}"

rm -rf "$SORTIE"; mkdir -p "$APP/web"

# Le PAYLOAD est celui du dépôt, à l'octet — une sonde qui mesurerait une copie modifiée ne
# mesurerait pas l'application.
cp "$RACINE/index.html" "$RACINE/manifest.webmanifest" "$RACINE/logo-glyph.svg" "$APP/web/"
cp "$RACINE"/*.png "$RACINE"/favicon.ico "$RACINE"/favicon.svg "$APP/web/" 2>/dev/null || true
cp -R "$RACINE/vendor" "$APP/web/"

cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>ACProbe</string>
  <key>CFBundleDisplayName</key><string>Sonde AC</string>
  <key>CFBundleIdentifier</key><string>fr.aidescognitives.probe</string>
  <key>CFBundleExecutable</key><string>ACProbe</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>17.0</string>
  <key>UILaunchScreen</key><dict/>
  <key>UISupportedInterfaceOrientations</key>
  <array><string>UIInterfaceOrientationPortrait</string></array>
</dict></plist>
PLIST

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
VER="$(xcrun --sdk iphonesimulator --show-sdk-version)"
swiftc -parse-as-library -sdk "$SDK" -target "arm64-apple-ios${VER}-simulator" \
       -o "$APP/ACProbe" "$RACINE/native/probe/ios/ACProbe.swift"

xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" fr.aidescognitives.probe 2>/dev/null || true
exec xcrun simctl launch --console-pty "$UDID" fr.aidescognitives.probe
