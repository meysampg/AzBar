#!/bin/zsh
# Captures README screenshots from a connected, unlocked iPhone using the DEBUG demo mode
# (AzBar/App/DebugLaunch.swift). Demo mode uses an in-memory store, so real progress is untouched.
#
# Usage: Tools/capture_screenshots.sh [device-udid]
set -euo pipefail
cd "$(dirname "$0")/.."

UDID="${1:-00008030-000511D93CC0202E}"
BUNDLE_ID="com.github.meysampg.azbar"
OUT="docs/screenshots"
DERIVED="build-shots"
SCREENS=(today path learn-wordbank learn-fillblank learn-cloze lesson-complete reader library poet:7 category:24 review progress badge fal fal-result settings about)

xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" -allowProvisioningUpdates build

APP="$DERIVED/Build/Products/Debug-iphoneos/AzBar.app"
xcrun devicectl device install app --device "$UDID" "$APP"

mkdir -p "$OUT"
i=1
for screen in $SCREENS; do
  name="${screen//:/-}"
  file="$(printf '%s/%02d-%s.png' "$OUT" "$i" "$name")"
  echo "==> $screen -> $file"
  xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE_ID" -- \
    -AzBarDemo YES -AzBarScreen "$screen"
  sleep 4
  xcrun devicectl device capture screenshot --device "$UDID" --destination "$file"
  sips -Z 1000 "$file" >/dev/null  # keep the repo small
  i=$((i + 1))
done

# Leave the phone on the real (non-demo) app.
xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE_ID"
rm -rf "$DERIVED"
echo "Done. Screenshots are in $OUT"
