#!/bin/bash
# Captures the Apple Watch store screenshots (docs/watch_app.md, "Store screenshots").
# Needs: a booted Apple Watch Ultra 3 simulator (422x514) with the watch app
# built in Debug WITH the DEBUG flag (the target's Debug config doesn't set it):
#   xcodebuild -project ios/Runner.xcodeproj -target HabittWatch -sdk watchsimulator \
#     -configuration Debug -arch arm64 CODE_SIGNING_ALLOWED=NO \
#     SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG SYMROOT=<dir> build
#   xcrun simctl install <udid> <dir>/Debug-watchsimulator/HabittWatch.app
# and the fixtures from watch_fixtures_test.dart (generated today).
#   SIM=<udid> tool/store_screenshots/capture_watchos.sh [lang ...]
set -euo pipefail
cd "$(dirname "$0")/../.."
SIM="${SIM:-booted}"
BID=com.shellz.habitt.watchkitapp
FIX="$PWD/marketing/watch_screenshots/fixtures"
OUT=marketing/watch_screenshots/watchos
if [ $# -gt 0 ]; then LANGS=("$@"); else LANGS=(en de es fr it pt tr bs); fi

open_id() {
  case "$1" in
    log_amount) echo 1004 ;;
    log_duration) echo 1003 ;;
    *) echo "" ;;
  esac
}

for lang in "${LANGS[@]}"; do
  mkdir -p "$OUT/$lang"
  i=1
  for shot in today log_amount log_duration day_complete; do
    SIMCTL_CHILD_HABITT_SCREENSHOT_SNAPSHOT="$FIX/$lang/$shot.json" \
      SIMCTL_CHILD_HABITT_SCREENSHOT_OPEN="$(open_id "$shot")" \
      xcrun simctl launch --terminate-running-process "$SIM" "$BID" \
      -AppleLanguages "($lang)" -AppleLocale "$lang" >/dev/null
    sleep 4
    xcrun simctl io "$SIM" screenshot "$OUT/$lang/${i}_$shot.png" >/dev/null 2>&1
    echo "$OUT/$lang/${i}_$shot.png"
    i=$((i + 1))
  done
done
