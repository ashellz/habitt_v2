# Habitt v2 — Support Asks

## Overview

Habitt has no ads, no tracking and no account, and it stays free. The only way
it keeps going is people who like it chipping in, so the app asks for support
in a few carefully limited places. The principles:

- **Nudge only.** Nothing is locked. Themes and cloud backup are free for
  everyone. The words "premium" and running-cost claims are never used.
- **Never nag.** At most one unprompted ask per calendar day, a dismissable
  banner that backs off for longer each time, and nothing at all for people who
  already support the app.
- **Local only.** All state lives in `SharedPreferences`. None of it is synced
  or backed up, so a repeated ask on a second device is acceptable and
  `docs/backup_system.md` is unaffected.
- **Honour based.** Ko-fi donations cannot be detected. "I already donated" is a
  local flag that hides the asks and unlocks nothing.

State and rules live in [`SupportProvider`](../lib/providers/support_provider.dart)
and the pure [`AskBudget`](../lib/services/ask_budget.dart). Surfaces live in
[`lib/widgets/support/`](../lib/widgets/support).

## The surfaces

| Surface | Where | When it shows | Spends the budget? |
|---|---|---|---|
| **Review prompt** (native) | after the celebration, or at launch/resume | first perfect-days streak of 7, 90-day guard, native review available | yes |
| **Milestone support card** | inside the streak celebration dialog | the celebration shows and the streak crossed 7 or 30 | yes |
| **Main-page banner** | end of the habit list (list view) | 7 days of use, 10 completions, dismiss schedule, budget free | no, it yields |
| **Support sheet** | theme pick, opening cloud backup setup | at most every 30 days | no, user-initiated |
| **"Support Habitt" row** | bottom of the theme picker and the backup sheet | always, unless hidden | no |
| **Supporter thank-you** | Profile card | active subscription | no |

All support surfaces open the existing support page (`PaywallPage`) through
[`openSupportPage`](../lib/util/support_navigator.dart), which re-reads the
subscription when the page closes.

## Who is never asked (`asksHidden`)

`SupportProvider.asksHidden = donated || isSupporter || !platformSupportsAsks`.
It hides the banner, the milestone card, the sheet and the rows. It does **not**
suppress the review prompt: that is not a support ask, though it still takes
part in the budget.

- `isSupporter` reads `BillingService.hasPro`, refreshed on resume and after the
  support page closes (`refreshSupporter`). Billing is injected into the provider
  so it never imports RevenueCat.
- `platformSupportsAsks` is true on iOS and Android only, where billing is
  configured. Elsewhere the support page cannot work.

## The ask budget

[`AskBudget`](../lib/services/ask_budget.dart) allows one unprompted ask per
calendar day. There are two kinds of ask:

- **Interruptive** (`AskKind.review`, `AskKind.milestoneBanner`) claim the day.
  `tryClaim` succeeds if nothing claimed today, or if the same kind claims again
  (re-evaluating one ask is harmless). A second, different ask the same day is
  refused, so the review never shares a day with another ask.
- **Ambient** (the main-page banner) never claims. It shows only while nothing
  has claimed today (`mainBannerAllowed`) and hides itself when an interruptive
  ask claims later that day. It is persistent, so if it claimed the budget it
  would starve the others forever.

A claim from another day, including a future one left by a clock moved ahead and
back, does not count. Days are compared as `yyyy-MM-dd` keys, never as 24 h
spans, so DST cannot move a boundary.

User-opened surfaces (the sheet, the rows, the support page) are exempt.

## The streak moment

[`runStreakMoment`](../lib/util/streak_moment.dart) is the single entry point
for everything that can happen when the perfect-days streak may have grown. It is
called from `home_page` on launch and on resume, and from the past-day completion
path. The celebration is always on; there is no preference for it. Steps:

1. Hold `StateProvider.streakCelebrationPendingOrActive` so the insight sheet
   defers. A second trigger while one is running is ignored.
2. Recompute the streak and record whether it ever reached 7
   (`SupportProvider.noteStreak`).
3. Evaluate the celebration
   ([`evaluateStreakCelebration`](../lib/util/perfect_streak_celebration.dart)).
4. Pick at most one ask with `planMomentAsk`, in the order of
   `kMomentAskPriority`: **review first, then the milestone card**. The review is
   possible when the 7-streak was reached, the 90-day guard has passed and the
   native review is available. The card is possible when a milestone was crossed
   (highest wins, a back-filled day can jump over one) and asks are not hidden.
   The budget is claimed only after the ask is known to be possible.
5. Show the celebration (with the card if it won), then request the review
   **after** the dialog is dismissed, never on top of it.

Net effect: at the first 7-day streak most users get the review prompt; the
support card first appears at 30 days. Users already covered by the review's
90-day guard get the card at 7. To flip the priority, reorder
`kMomentAskPriority`. A review blocked by the budget is not lost:
`support_streak7_reached` persists, so it fires on a later free day.

## Review prompt

`FeedbackService.canRequestReview()` (90-day guard on `review_last_requested_ms`
plus the platform's `isAvailable()`, no side effects) and `requestReview()`
(requests and stamps the guard). The old completion-triggered review is gone.
`HabitProvider` only counts first-time completions (`total_habit_completions`),
which the banner needs.

## Main-page banner

`SupportProvider.bannerVisible` is true when: not `asksHidden`, budget not
claimed today, at least 7 calendar days since `support_first_seen_ms` (existing
users get 7 days of grace after the update), at least 10 completions, and the
dismiss schedule allows it.

Dismiss (the X) hides it for **30 days, then 45, then 90, staying at 90**
(`bannerDismissDays`, calendar-day arithmetic). A stored next day more than 90
days ahead can only come from a clock moved ahead and back, so it is ignored.
"I already donated" hides it forever.

## Milestone support card

[`MilestoneSupportCard`](../lib/widgets/support/milestone_support_card.dart) sits
below the day strip in the celebration dialog (`showSupportCard`). It is styled
in the streak orange with a heart, deliberately unlike the neutral banner. It
adds no animation or popup. "See ways to support" closes the dialog first, then
opens the support page.

## Support sheet

[`SupportSheet`](../lib/widgets/support/support_sheet.dart) says Themes and cloud
backup are free for everyone and that supporters keep Habitt going. One column:
"See ways to support", "Not now", then the "I already donated" link below both.

[`maybeShowSupportSheet`](../lib/util/support_sheet_flow.dart) is called when the
user picks a theme different from the current one (the theme is applied first,
then a short pause) and when `BackupSheet` opens while signed out. It shows when
`sheetDue`: not hidden, and never shown or last shown `sheetRepeatDays` (30)
calendar days ago. It is stamped **before** it is presented, so any dismissal
waits out the full period. It waits while the streak celebration is up and stays
due.

## "I already donated"

On the banner, the card and the sheet: sets `support_donated`, and
[`showDonationThanks`](../lib/util/support_thanks.dart) shows the thank-you toast
(`StatusOverlayPopupController`), three confetti bursts fanning down from it, and
plays `completion_all.mp3` unless the user turned completion sounds off. It runs
on detached tickers, so it outlives the widget that triggered it.

## State

All keys are `SharedPreferences`, local only.

| Key | Meaning |
|---|---|
| `support_first_seen_ms` | first launch with this feature, "7 days of use" counts from here |
| `support_donated` | "I already donated" |
| `support_ask_day` / `support_ask_kind` | today's budget claim |
| `support_streak7_reached` | the perfect-days streak has reached 7 (review milestone) |
| `support_banner_dismissals` / `support_banner_next_day` | banner dismiss schedule |
| `support_sheet_last_shown` | the support sheet's 30-day timer |
| `review_last_requested_ms` | the review's 90-day guard (pre-existing) |
| `total_habit_completions` | first-time completions, written by `HabitProvider` (pre-existing) |
| `celebratedPerfectStreak` / `streakDialogShownDate` | streak celebration dedup (pre-existing) |

## Copy rules

Never call a free feature "premium" and never claim running costs (Backup uses
only the user's own Drive or iCloud). Strings follow the app's rules: new keys go
at the bottom of every ARB file. The user-facing wording is "support", the
internal key names (`getPremium`, `paywallUpgradeTo`) are historical.

## Testing

Everything is built to be unit-testable: `AskBudget` takes an injected clock and
persistence callback, `SupportProvider` takes the clock, the billing read/check
and the platform flag, and `donationSound` in `support_thanks.dart` is replaceable
so tests never touch the audio plugin. See `test/services/ask_budget_test.dart`,
`test/util/streak_milestones_test.dart`, `test/providers/support_provider_test.dart`
and `test/widgets/support_*_test.dart`. `runStreakMoment` itself needs a
`BuildContext` and is covered through the pure functions it calls.

## Changing it

- **New ask:** add an `AskKind` if it is interruptive (an ambient one checks
  `mainBannerAllowed` instead), add it to `kMomentAskPriority`, and give it a
  `possible` condition in `runStreakMoment`.
- **Different schedule:** `bannerDismissDays`, `bannerMinDaysOfUse`,
  `bannerMinCompletions`, `sheetRepeatDays` in `SupportProvider`;
  `kSupportMilestones` and `kReviewStreakMilestone` in
  [`streak_milestones.dart`](../lib/util/streak_milestones.dart).
- **Maintenance rule:** any change to the asks, their timing or their state keys
  must also update this document.
