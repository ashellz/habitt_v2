## Plan: Habit Details Page and Optimized Habit Stats

Replace edit-on-tap sheet flows in the active list surfaces with a dedicated Habit Details page, keep HabitSheet as the edit surface opened from the top-right circle button, and introduce a cached HabitStatsProvider that minimizes recomputation by using per-habit cache entries plus explicit invalidation on mutation and day-boundary changes.

**Steps**
1. Phase 1 - Navigation and scope wiring
1. Add a new Habit Details route/screen and wire habit argument input.
2. Replace edit entry in NewHabits category rows so tapping a habit opens Habit Details instead of opening HabitSheet directly. This is the primary flow and blocks downstream UI integration.
3. Make HabitsPage reorderable cards tappable and open the same Habit Details page (user-confirmed second entry point). This can run in parallel with step 2 after step 1 exists.
4. Keep add-new flow unchanged (HabitSheet without habit argument), and keep existing old CalendarPage flows unchanged unless explicitly requested.

2. Phase 2 - Build Habit Details UI surface
1. Implement page structure from screenshot: top bar (back, title, top-right edit circle button), hero habit card, notes block, stats section, completion ratio section, and consistency calendar section.
2. Top-right circle button opens HabitSheet in edit mode with current habit and returns to details page context on close.
3. Hero habit card reuses existing display patterns from MainHabitInfo/HabitWidget for name + secondary line (description or amount/duration), and adds a fixed 79% strength ring using a real circular progress visual.
4. Implement interactive primary action row that mirrors NewHabitProgress behavior: tap animation, haptics, complete/log-progress branching, and long-press completion.
5. For the leading icon inside this action, render a downsized progress/check visual based on NewHabitProgress with IgnorePointer and inverted check icons (check-on/off-inverted-dark/light).

3. Phase 3 - Notes autosave with debounce
1. Bind notes text field to habit.description with controller seeded from current habit value.
2. Add debounced autosave (500ms target) that updates only when content changed, avoiding write spam.
3. Flush pending save on page dispose/pop to avoid losing trailing edits.
4. Persist via HabitProvider update path so storage and dependent UI stay consistent.

4. Phase 4 - New HabitStatsProvider with optimized caching
1. Create HabitStatsProvider with per-habit cache map and lightweight computed model for details page stats.
2. Cache strategy:
- Keep computed stats keyed by habitId.
- Store cache metadata: computedAt, source day window bounds, and relevant timestamp fingerprint from habit.timestamps.
- Return cached stats when the habit fingerprint and day-window keys are unchanged.
3. Invalidation strategy:
- Mark specific habit dirty on mutation methods: completeHabit, skipHabit, updateHabitAmountCompleted, updateHabitDurationCompleted, updateHabit, removeHabit.
- Clear rolling-window metrics on new-day detection (using normalized date guard).
- Remove cache entry on delete.
4. Metric computation rules (user decisions applied):
- Skipped stat = missed count = scheduled days where habit was not completed.
- Completion ratio = last 7 days completion rate for this habit.
- Best/Worst weekday (last month) = highest/lowest completion rate per weekday (completed/scheduled), rendered as percentages.
5. Avoid duplicate schedule logic by extracting/reusing schedule-appearance checks from HabitProvider in a shareable utility or provider-exposed helper.

5. Phase 5 - Habit model additions for creation boundaries
1. Add Habit.createdAt (UTC) to support calendar disabled days before creation.
2. Set createdAt on habit creation.
3. Backward compatibility for existing records:
- If missing, infer from oldest day entry containing that habit; fallback to now if history absent.
4. Update Hive adapter generation and serialization maps safely without breaking existing persisted data.

6. Phase 6 - Habit details stats and calendar widgets
1. Add dedicated widgets for stat cards and completion ratio section matching screenshot layout and app color tokens.
2. Build a dedicated habit-details calendar widget using TableCalendar (separate from existing calendar widget), with day-cell visual language based on SelectableMonth styling.
3. Disable dates before habit.createdAt and after today.
4. Drive day highlighting from per-day habit completion state/intensity for last month view and keep interactions read-only unless future scope expands.

7. Phase 7 - Provider registration and integration
1. Register HabitStatsProvider in app provider tree and connect dependencies so HabitProvider can notify invalidation events.
2. Keep computation lazy (on demand by Habit Details page) to avoid startup cost.
3. Ensure provider notifications are scoped so unrelated screens do not rebuild excessively.

8. Phase 8 - Verification and regression checks
1. Navigation checks:
- Tap habit in NewHabits opens Habit Details.
- Tap habit card in HabitsPage opens Habit Details.
- Top-right edit button opens HabitSheet edit mode and saving reflects back in details and lists.
2. Interaction checks:
- Mark-as-complete / completed / log-progress behavior matches NewHabitProgress (tap, long-press, haptics, dialog path).
- Notes autosave writes after debounce and on exit.
3. Stats checks:
- Missed count, streak cards, amount card, 7-day completion ratio, and best/worst weekday percentages validate against synthetic data.
- Cache hits occur when no relevant changes; recompute triggers only on dirty/new-day/edit cases.
4. Calendar checks:
- Disabled day bounds correct (before createdAt and after today).
- Visual style aligns with SelectableMonth-inspired circular cells and screenshot proportions.

**Relevant files**
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/main_page/habits/new_habit_category.dart - replace onTap edit flow to open Habit Details page.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/pages/main_pages/habits_page.dart - make reorderable card open Habit Details.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/sheets/habit_sheet.dart - keep edit behavior; ensure detail page entry uses this in top-right button.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/main_page/habits/habit_widget/new_habit_progress.dart - replicate interaction and progress behavior.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/default/checkmark.dart - inverted check variant adaptation or sibling widget.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/default/new_circle_button.dart - top-right edit affordance.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/default/selectable_month.dart - visual reference for calendar day styling.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/models/habit.dart - add createdAt and update copy/serialization support.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/hive/hive_adapters.g.dart and /Users/shellz/Documents/GitHub/habitt_v2/lib/hive/hive_adapters.dart - persist new model field safely.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/providers/habit_provider.dart - invalidate HabitStats cache on mutations and expose/reuse schedule checks.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/providers/stats_provider.dart - leave global stats unchanged unless dependency wiring requires small adjustments.
- /Users/shellz/Documents/GitHub/habitt_v2/lib/main.dart - provider registration and dependency wiring.
- New files to add:
  /Users/shellz/Documents/GitHub/habitt_v2/lib/pages/other_pages/habit_details_page.dart
  /Users/shellz/Documents/GitHub/habitt_v2/lib/providers/habit_stats_provider.dart
  /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/habit_details/new/habit_details_calendar.dart
  /Users/shellz/Documents/GitHub/habitt_v2/lib/widgets/habit_details/new/habit_detail_stats_sections.dart

**Verification**
1. Run flutter analyze and ensure no new diagnostics in touched files.
2. Run targeted interaction test pass on iOS and Android for main flows (open details, edit via sheet, complete/log progress, notes autosave).
3. Seed controlled habit/day data and verify each metric output against manual calculations.
4. Validate cache behavior with debug logs or assertions: no redundant recompute on repeated opens without state change.

**Decisions**
- Included scope: NewHabits and HabitsPage entry points open Habit Details.
- Excluded scope: old CalendarPage/HabitWidget EditHabitPage flow unless requested in follow-up.
- Skipped metric definition: scheduled-but-not-completed days (not current habit.skipped boolean).
- Best/Worst weekday metric: completion rate percentage per weekday over last month.
- Notes autosave: debounced.
- Habit creation boundary: add createdAt with backward-compatible fallback.
