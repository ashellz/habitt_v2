# Goal Check-in

How Habitt suggests goal changes (the weekly check-in) and lets the user lower **today's** goal only (a "lighter day"). It replaces the old per-habit insight sheets that came from the habit strength score (`InsightSheetFlow`, `AdjustTargetDialog`, `HabitStrengthInsightTextService`, all deleted). The strength score itself is unchanged and still feeds stats.

OpenSpec change: `openspec/changes/goal-check-in/`.

## Pieces

| File | Role |
|---|---|
| `lib/services/goal_check_in_analyzer.dart` | Pure Dart. Reads 14 days of `Day` snapshots (`collect`), works out lower/raise suggestions (`analyze`), clean rounding steps (`GoalSteps`). |
| `lib/services/lighter_day_policy.dart` | Pure Dart. Who gets the evening offer, which values, the weekly allowance, "streak ends tonight", priority. |
| `lib/services/lighter_day_offers.dart` | Builds today's offers from `HabitProvider` (+ `StatsProvider` for the perfect-days streak). The evening time (20:25). |
| `lib/services/goal_check_in_store.dart` | SharedPreferences: weekly last-shown date, cooldowns, lighter-day sheet shown today. |
| `lib/services/goal_check_in_notifications.dart` | Schedules / cancels the 20:25 notification (today + a tentative one for tomorrow). |
| `lib/services/pending_day_goal_queue.dart` | Durable queue for the notification's "Count it" button (background isolate → app). |
| `lib/util/goal_check_in_flow.dart` | When the sheets show on the main page; applies the weekly sheet's actions. |
| `lib/widgets/goal_check_in/` | `GoalCheckInSheet`, `GoalSuggestionCard`, `LighterDaySheet`, `LighterDayBadge` (dashed check). |
| `Habit.dayGoal` | Today's lighter goal, day-state. |

## Today's goal (`Habit.dayGoal`)

- `int`, 0 = none. Same unit as the usual goal: a count for amount habits, **seconds** for duration habits. Ignored for time-of-day habits (`hasDayGoal` is false).
- `effectiveAmount` / `effectiveDuration` return it when set, else the usual `amount` / `duration`. Everything that shows or judges **today's** progress reads these: completion (`updateHabitAmountCompleted`, `updateHabitDurationCompleted`, goal edits), `habit_progress.dart` (card pie + text, widget snapshot), the watch log `target` in the snapshot (`WidgetSnapshotBuilder`), the log progress dialog, the habit card displays, the timer pill / timer target, notification progress text, the category progress on the home page.
- Stats (`StatsProvider`, `HabitStatsProvider`, the strength score) and the analyzer keep the usual goal and the real logged values. A lighter day still counts as **completed** everywhere (streaks, perfect days, completion rate), because `completed` is true.
- `Habit.setDayGoal(goal)` sets it, stamps `timestamps['dayGoal']` and re-evaluates `completed`. `HabitProvider.setTodayGoal(id, goal, {context})` is the app entry point: saves the habit and today's `Day`, updates period counters, notifications and the perfect-days streak, like logging progress.
- Editing the usual goal to at or below the lighter goal, or changing the tracking type, clears it.
- Day-state: in `dayStateKeys`, merged with the day's progress, reset at rollover, kept in `Day` snapshots so history knows the day was lighter. See `backup_system.md`.

## Weekly check-in

**Which days count** (`GoalCheckInAnalyzer.collect` + `qualifying`): the 14 calendar days before today, days the habit appears in a `Day` snapshot, not skipped, not paused/inactive, not deleted, and whose **usual** goal equals today's usual goal (days before the last goal change drop out). At least 7 such days, else no suggestion. A day's value is the real amount logged, scored against the usual goal (a lighter day of 18 on a 30 goal is a 0.6 day).

**Which habits**: required, amount or duration tracking, not sleep (minutes with a tolerance), goal > 0, not paused or deleted.

**Rules** (`GoalCheckInAnalyzer`):

- *All-or-nothing* → no suggestion: ≥ 60% of the below-goal days had nothing logged and fewer than 2 were partial. A smaller goal is the wrong advice for a habit that's done fully or not at all; the evening "a short one today?" offer covers those days.
- *Lower*: hit rate < 40%, or ≥ 3 lighter days. Value: median of the non-zero values (only the non-zero **below-goal** days when the lighter days alone triggered it), rounded down to a clean step, must be < goal and > 0.
- *Raise*: hit rate ≥ 85% and ≥ 1.2× the goal on ≥ 60% of days. Value: median, capped at 1.5× the goal, rounded down, must be > goal.
- *Agreement*: the same rule must hold on the most recent 7 qualifying days (≥ 4 of them; lighter-day threshold 2 there).

**Clean steps** (`GoalSteps`): amounts 1 below 10, 5 below 100, else 10. Durations 1 min below 10 min, 5 min below 2 h, else 15 min. Lighter-day values use the step for the **usual goal's** size.

**When it shows** (`GoalCheckInFlow`): on main page open / resume / habit changes (debounced like the old flow, same guards: backup initialised and not syncing, no streak celebration, no other check-in sheet open), when `goal_check_in_last_shown` is 7+ days old or missing, and only if at least one habit has a suggestion. Nothing to suggest doesn't restart the clock. The lighter-day sheet goes first when both are due.

**Actions**: Apply sets the usual goal (`HabitProvider.updateHabit`) and starts a 14-day cooldown for **both** directions. Not now starts a 14-day cooldown for that direction. Undo (while the sheet is open) restores the old goal / clears the cooldown. Apply all applies every open card. Later / close records nothing.

## Lighter day (evening offer)

**Eligible** (`LighterDayPolicy.evaluate`): required, amount/duration, due today, not completed / skipped / paused, no lighter goal yet today, usual goal ≥ 2 steps, lighter days left this week, and one reason:

1. the previous scheduled day was missed or partial,
2. the habit's streak has misses (`HabitProvider.consecutiveMissesFor` > 0 on a running streak),
3. hit rate over the qualifying recent days < 50% (≥ 4 days).

**Streak ends tonight** (always qualifies, ignores the reasons and the allowance): nothing logged today and either the habit's own streak is at `kStreakMissTolerance` misses, or the perfect-days streak is (`StatsProvider.perfectDaysTailMisses`). A no-progress day would be the 3rd miss and break it. With lighter days left: the normal offer, titled "Your N-day streak ends tonight". With none left: the **save streak** variant, "Log any amount to keep your N-day streak", opening the log progress dialog: a partial day is neutral for the streak, so it survives without growing and no allowance is used.

**Values** (`offeredValues`, up to 3): with progress *p*: *p* itself ("18 · done", completes today at once), *p + ⅓(goal−p)*, *p + ⅔(goal−p)*. With nothing logged: 25%, 40%, 60% of the goal (at least one step).

**Allowance**: 2 per habit per Monday-to-Sunday week, counted from this week's `Day` snapshots with `hasDayGoal` (`lighterDaysThisWeek`). Derived from the data, nothing extra stored, syncs on its own. 2 a week caps it at 4 in 14 days, and 3 lighter days in 14 already make the weekly check-in suggest lowering the usual goal.

**Priority** (`pick`): streak ends tonight, then missed yesterday, then closest to the goal, then list order.

**In-app sheet**: on open / resume from **20:25** on, the top offer not yet shown today (`lighter_day_shown_<id>_<date>`), once per habit per day.

## Notification

- `GoalCheckInNotifications.refresh` runs from every flow evaluation (app open, resume, habit changes) and after saving notification settings. It schedules one notification for **20:25 today** for the top offer (only before 20:25; after that the in-app sheet covers it) and cancels it when nothing is eligible.
- Tomorrow: a tentative notification for 20:25 tomorrow for the first habit not done today that is due tomorrow (it would be "missed yesterday" with no progress). Replaced on the next evaluation, so it only fires when the app isn't opened.
- Fixed ids `1950000000` (today) and `1950000001` (tomorrow), payload `notification_type = goal_check_in`, `habit_id`, `habit_day`, `goal` (the progress at scheduling time).
- Buttons: **Count it** (only with progress; `SilentBackgroundAction` → `PendingDayGoalQueue` → `setTodayGoal` when the app drains, entries for a past day are dropped), **Choose a smaller goal** / **Log progress** (opens the app; `GoalCheckInFlow.requestLighterDay` shows that habit's sheet right away, the main page listens to `GoalCheckInFlow.requestedHabit`), **Keep** (dismiss).
- Off when `NotificationsProvider.isGoalCheckInEnabled` is false: its own toggle ("Goal check-in" in notification settings, on by default, key `notifications_goal_check_in_enabled`) and the master switch.

## How it looks

- Habit card: a completed lighter day shows `LighterDayBadge` (dashed ring + check) instead of the filled checkmark, and "Usual goal X" next to the progress text.
- Home week strip: the day's arc is dashed when every habit is done and at least one with a lighter goal (`HabitProvider.dayHasLighterGoal`).

## Local state keys

| Key | What |
|---|---|
| `goal_check_in_last_shown` | ISO time the weekly sheet last showed |
| `goal_check_in_cooldown_<habitId>_<lower\|raise>` | ISO time the cooldown ends |
| `lighter_day_shown_<habitId>_<yyyy-MM-dd>` | the lighter-day sheet showed for that habit that day |
| `notifications_goal_check_in_enabled` | the notification toggle |
| `pending_day_goals` | queued "Count it" presses |

All device-local, never synced. The old `habit_strength_insight_shown*` keys and `Habit.insightPopstonedUntil` are no longer read (kept, harmless).
