# Demo data for website screenshots

`habitkit_demo_export.json` is a fake HabitKit export: 8 habits, ~6 months of history (improving consistency, last 12 days perfect, 15-day streak). Regenerate with `python3 gen_habitkit_demo.py out.json`.

## Setup (fresh install, iOS 26 simulator, iPhone 17 Pro)
1. Run `./push_to_simulator.sh` in a Terminal (the simulator must be booted). It puts the JSON in the simulator's Files app. Then Profile → Backup & Sync → Import from other apps → HabitKit → Merge.
2. Edit habits (imported ones are all checkbox + "Any time"):
   - Drink water: Amount 8, amount name **glasses** (not the default "times"), Afternoon; log 5.
   - Read: Amount 20, amount name **pages**, Any time; log 0 (the list shows "0 / 20 pages").
   - Meditation: Duration 20m, Evening.
   - Morning run, Wake up early: Morning. Gym: Afternoon.
   - Turn on notifications on Drink water (08:00, 11:00).
3. Complete today: Vitamins, Wake up early, Morning run.
4. (Optional) clean status bar: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`

## Screenshots the site uses (light unless noted) → website/assets/img/screens/NAME.webp
day-plan-light (Home in the timeline view), timer-dark (the "Start a timer" sheet, dark mode), home (+dark), list (+dark, home scrolled to the habit list), charts (+dark, habit details scrolled to "Strength over time", range ALL), calendar (+dark, Calendar tab), streak-light (the streak celebration popup on relaunch; wait about 2 s after the sheet appears, until the day strip is fully highlighted and nothing moves, or it looks half-animated), schedule-light (day schedule picker), reminders-light (Edit Habit scrolled to the notifications widget with several times), edit-light (Edit Habit), import-dialog-light (Merge/Replace dialog), backup-light (Backup & Sync), templates-light (Select Habit).

Capture with the Device Hub screenshot button (or `xcrun simctl io booted screenshot NAME.png`), then convert:
```bash
for f in *.png; do cwebp -quiet -q 82 -resize 720 0 "$f" -o "website/assets/img/screens/${f%.png}.webp"; done
```
