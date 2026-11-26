#!/bin/bash
# Captures the Wear OS store screenshots (docs/watch_app.md, "Store screenshots").
# Needs: a booted round Wear OS emulator with the debug Wear app installed, and
# the fixtures from watch_fixtures_test.dart (generated today).
#   tool/store_screenshots/capture_wear.sh [lang ...]
# Each shot waits until its screen is really drawn (a marker text in the
# uiautomator dump), not a fixed time: right after an install the app starts
# slowly and fixed waits caught the splash or turned the list scroll into a tap.
# Exits 1 (after capturing everything) if a screen never showed up.
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

# `<attr>="<text>"` as it appears in the uiautomator dump, for the fixture
# string <key> of <lang>/<shot> (the dump escapes & < > " but keeps ').
attr_of() {
  python3 -I - "$FIX/$1/$2.json" "$3" "$4" <<'PY'
import json, sys
v = json.load(open(sys.argv[1]))["strings"][sys.argv[2]]
for a, b in (("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ('"', "&quot;")):
    v = v.replace(a, b)
print(f'{sys.argv[3]}="{v}"')
PY
}

# What marks <shot>'s screen as drawn: the list's title, the log screen's
# "More" button, the day-complete title.
marker() {
  case "$2" in
    today) attr_of "$1" "$2" today text ;;
    log_*) attr_of "$1" "$2" watchMore content-desc ;;
    day_complete) attr_of "$1" "$2" dayComplete text ;;
  esac
}

# 9:41 on the clock (needs `adb root`; ignored where it isn't allowed)
set_941() { "$ADB" shell "date $(date +%m%d)0941$(date +%Y).00" >/dev/null 2>&1 || true; }

dump() { "$ADB" exec-out uiautomator dump /dev/tty 2>/dev/null; }

# Waits (up to 60 s) until the app's window shows <needle>; 1 if it never does.
wait_for() {
  local deadline=$((SECONDS + 60))
  while [ $SECONDS -lt $deadline ]; do
    dump | grep -qF "$1" && return 0
    sleep 1
  done
  return 1
}

# Top of the first section label (<needle>) in the dump, empty if not found.
label_top() {
  dump | tr '>' '\n' | grep -F "$1" | grep -o 'bounds="\[[0-9]*,[0-9]*' | head -1 | sed 's/.*,//' || true
}

# The list shot: the first section label's top at LABEL_Y (+-6), the same in
# every language, with the clock scrolled away. A fast swipe flings a different
# distance each time, so it first nudges the list to PRE_Y with slow
# (fling-free) swipes, always downwards and only ~3/4 of the way so it never
# overshoots. The clock only hides while the list moves, so the screenshot is
# taken right after one more short slow swipe; that one doesn't travel the same
# distance every time, so the result is measured and the shot retaken if off.
PRE_Y=120
LABEL_Y=84
scroll_list() {
  local n top delta
  for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
    top=$(label_top "$1")
    [ -z "$top" ] && { sleep 1; continue; } # a dump can come back empty
    delta=$((top - PRE_Y))
    [ $delta -le 2 ] && [ $delta -ge -3 ] && return 0
    [ $delta -lt 0 ] && return 1 # overshot
    # ~20 px of every swipe goes to touch slop before the list moves
    "$ADB" shell input swipe 227 300 227 $((300 - delta * 3 / 4 - 20)) 1500
    sleep 1
  done
  return 1
}

# Launches the app on <lang>/<shot>'s fixture and waits for its screen.
launch() {
  "$ADB" shell "run-as $PKG sh -c 'mkdir -p files && cat > files/screenshot.json'" < "$FIX/$1/$2.json"
  "$ADB" shell am force-stop "$PKG"
  local extra=() id
  id=$(open_id "$2")
  [ -n "$id" ] && extra=(--es screenshotOpen "$id")
  "$ADB" shell am start -n "$PKG/com.shellz.habitt.wear.MainActivity" \
    --es screenshotSnapshot screenshot.json ${extra[@]+"${extra[@]}"} >/dev/null
  wait_for "$(marker "$1" "$2")" || return 1
  sleep 1.5 # let the ring and number animations finish
}

# Takes <lang>/<shot> into <file>; 1 if it couldn't be taken right.
shoot() {
  local lang=$1 shot=$2 file=$3 needle top try
  if [ "$shot" != today ]; then
    launch "$lang" "$shot" || return 1
    set_941 # waiting can take minutes: the clock back to 9:41 right before the shot
    sleep 2
    "$ADB" exec-out screencap -p > "$file"
    return 0
  fi
  needle=$(attr_of "$lang" "$shot" morning text)
  for try in 1 2 3 4 5; do
    launch "$lang" "$shot" && scroll_list "$needle" || continue
    set_941
    "$ADB" shell input swipe 227 300 227 240 1000
    sleep 0.8
    "$ADB" exec-out screencap -p > "$file"
    top=$(label_top "$needle")
    [ -n "$top" ] && [ $((top - LABEL_Y)) -le 6 ] && [ $((top - LABEL_Y)) -ge -6 ] && return 0
  done
  return 1
}

failed=()
for lang in "${LANGS[@]}"; do
  mkdir -p "$OUT/$lang"
  "$ADB" shell cmd locale set-app-locales "$PKG" --locales "$lang" >/dev/null 2>&1 || true
  i=1
  for shot in today log_amount log_duration day_complete; do
    if ! shoot "$lang" "$shot" "$OUT/$lang/${i}_$shot.png"; then
      echo "WARNING: $lang/$shot isn't right" >&2
      failed+=("$lang/$shot")
    fi
    echo "$OUT/$lang/${i}_$shot.png"
    i=$((i + 1))
  done
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Retake these: ${failed[*]}" >&2
  exit 1
fi
