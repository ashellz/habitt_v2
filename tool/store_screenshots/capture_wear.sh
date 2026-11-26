#!/bin/bash
# Captures the Wear OS store screenshots (docs/watch_app.md, "Store screenshots").
# Needs: a booted round Wear OS emulator with the debug Wear app installed, and
# the fixtures from watch_fixtures_test.dart (generated today).
#   tool/store_screenshots/capture_wear.sh [lang ...]
set -euo pipefail
cd "$(dirname "$0")/../.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
PKG=com.shellz.habitt
FIX=marketing/watch_screenshots/fixtures
OUT=marketing/watch_screenshots/wear_os
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
  "$ADB" shell cmd locale set-app-locales "$PKG" --locales "$lang" >/dev/null 2>&1 || true
  i=1
  for shot in today log_amount log_duration day_complete; do
    "$ADB" shell "run-as $PKG sh -c 'cat > files/screenshot.json'" < "$FIX/$lang/$shot.json"
    "$ADB" shell am force-stop "$PKG"
    # 9:41 on the clock (needs `adb root`; ignored where it isn't allowed)
    "$ADB" shell "date $(date +%m%d)0941$(date +%Y).00" >/dev/null 2>&1 || true
    extra=()
    id=$(open_id "$shot")
    [ -n "$id" ] && extra=(--es screenshotOpen "$id")
    "$ADB" shell am start -n "$PKG/com.shellz.habitt.wear.MainActivity" \
      --es screenshotSnapshot screenshot.json ${extra[@]+"${extra[@]}"} >/dev/null
    sleep 3
    # the list: scroll so the day bar and three rows (done, a third, not started) fit the round screen
    if [ "$shot" = today ]; then "$ADB" shell input swipe 227 380 227 240 600; sleep 2; fi
    "$ADB" exec-out screencap -p > "$OUT/$lang/${i}_$shot.png"
    echo "$OUT/$lang/${i}_$shot.png"
    i=$((i + 1))
  done
done
