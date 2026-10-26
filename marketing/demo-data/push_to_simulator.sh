#!/bin/bash
# Copies the demo HabitKit export into a booted simulator's Files app ("On My iPhone").
# Usage: ./push_to_simulator.sh            (uses the booted simulator)
#        ./push_to_simulator.sh <UDID>
set -e
UDID="${1:-booted}"
DIR="$(cd "$(dirname "$0")" && pwd)"
xcrun simctl launch "$UDID" com.apple.DocumentsApp >/dev/null
sleep 4
BASE="$(xcrun simctl getenv "$UDID" HOME)"
for g in "$BASE"/Containers/Shared/AppGroup/*; do
  id=$(/usr/libexec/PlistBuddy -c "Print :MCMMetadataIdentifier" "$g/.com.apple.mobile_container_manager.metadata.plist" 2>/dev/null || true)
  if [ "$id" = "group.com.apple.FileProvider.LocalStorage" ]; then
    mkdir -p "$g/File Provider Storage"
    cp "$DIR/habitkit_demo_export.json" "$g/File Provider Storage/HabitKit_export.json"
    echo "Done. In Habitt: Backup & Sync > Import from other apps > HabitKit > Browse > On My iPhone > HabitKit_export.json"
    xcrun simctl terminate "$UDID" com.apple.DocumentsApp
    exit 0
  fi
done
echo "Files storage not found; open the Files app once on that simulator and retry." >&2
exit 1
