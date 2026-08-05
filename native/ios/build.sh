#!/bin/bash
# Construit la coquille iOS et l'installe sur un simulateur.
#   usage : native/ios/build.sh [UDID]        (sans UDID : le premier appareil démarré)
#
# ⚠ CE SCRIPT EST UN OUTIL DE DÉVELOPPEMENT, PAS UNE CHAÎNE DE PUBLICATION. Il compile pour le
# SIMULATEUR (arm64-simulator, pas de signature). Une distribution réelle passe par Xcode et un
# compte Apple Developer — cf. la section « conséquence réglementaire » du plan de portage.
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/../.." && pwd)"
SORTIE="/tmp/ac-ios-app"
APP="$SORTIE/AidesCognitives.app"
BUNDLE="fr.aidescognitives.app"
UDID="${1:-$(xcrun simctl list devices booted -j | python3 -c 'import json,sys;d=json.load(sys.stdin)["devices"];print(next(x["udid"] for v in d.values() for x in v))')}"

rm -rf "$SORTIE"; mkdir -p "$APP/web"

# LE PAYLOAD EST CELUI DU DÉPÔT, À L'OCTET. La coquille n'embarque aucune variante : ce qui tourne
# en natif est exactement ce qui est servi sur le web, ce qui est toute la promesse du portage.
cp "$RACINE/index.html" "$RACINE/manifest.webmanifest" "$RACINE/logo-glyph.svg" "$APP/web/"
cp "$RACINE"/*.png "$RACINE"/favicon.ico "$RACINE"/favicon.svg "$APP/web/" 2>/dev/null || true
cp -R "$RACINE/vendor" "$APP/web/"

cat > "$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Aides cognitives</string>
  <key>CFBundleDisplayName</key><string>Aides cognitives</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE</string>
  <key>CFBundleExecutable</key><string>AidesCognitives</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>5.1.2</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>17.0</string>
  <key>ACOTABase</key><string>${AC_OTA_BASE:-}</string>
  <!-- ⚠ DÉVELOPPEMENT SEULEMENT : autorise http vers le réseau local, pour éprouver l'OTA contre
       un serveur de test sur la machine. En production la base est https et cette clé DISPARAÎT. -->
  <key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
  <key>UILaunchScreen</key><dict/>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
</dict></plist>
PLIST

# LA CLÉ PUBLIQUE EST COMPILÉE DEPUIS `ota/pubkey.b64` — jamais recopiée à la main : deux copies
# d'une clé finiraient par diverger, et le symptôme serait « aucune mise à jour n'arrive », muet.
# (En production elle vit dans le projet Xcode ; ici on la génère pour que le build soit reproductible.)
PUB="$(cat "$RACINE/ota/pubkey.b64" 2>/dev/null | tr -d '\n')"
printf 'let OTA_PUBKEY_B64 = "%s"\n' "$PUB" > "$SORTIE/OTAKey.swift"

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
VER="$(xcrun --sdk iphonesimulator --show-sdk-version)"
swiftc -parse-as-library -sdk "$SDK" -target "arm64-apple-ios${VER}-simulator" \
       -o "$APP/AidesCognitives" "$RACINE/native/ios/ACApp.swift" \
       "$RACINE/native/ios/OTA.swift" "$SORTIE/OTAKey.swift"

xcrun simctl install "$UDID" "$APP"
echo "✓ installée sur $UDID — lancer : xcrun simctl launch $UDID $BUNDLE"
