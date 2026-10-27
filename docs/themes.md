# Habitt v2 — Themes

## Overview

Users can pick an accent theme in Settings → Appearance. All themes are free for
everyone. A theme changes **only the accent role**: the colour of completed
things, primary buttons, selections and check marks. Everything else is the same
in every theme, so every theme is still recognisably Habitt:

- neutrals (`bg`, `habitBg`, `text`, greys, `border`, `field`, `pill`),
- semantic colours (`fail`, `error`, `mid`),
- the streak orange family (`orange*`, the fading-orange gradients),
- brand surfaces: the support page and its artwork, the app icon, the splash
  screen and onboarding artwork.

The default and the brand is **Habitt** (green). Its values are the same
constants the app always used, so with Habitt selected the app renders as before.

## How it works

[`ColorProvider`](../lib/providers/color_provider.dart) is still the single
runtime theme (about 150 files watch it). It holds a selected
[`AppTheme`](../lib/models/app_theme.dart) and merges that theme's accent into
the colour set it already animates:

- `ColorProvider._colsForDark(dark)` takes `main`, `mainButtonLeftGradient` and
  `mainButtonRightGradient` from `theme.accent(isDark: dark)`; everything else
  still comes from `Light`/`Dark` in `color_service.dart`.
- `setTheme(theme)` persists `app_theme_id` and calls the existing
  `_startTransition()`, so a switch animates exactly like a light/dark change.
  `main.dart`'s `ThemeData` and Cupertino theme are derived from `cp.main` and
  follow automatically.
- `mainTint` (10 % alpha) and `mainBorder` (20 % alpha) are soft versions of the
  accent for chips, badges and selections. Use them instead of literal hex.
- An unknown or missing stored id falls back to Habitt. There is **no migration**
  of the legacy `accent_name` (its picker was removed, everyone already saw
  Habitt green).

## The themes

Defined in [`ThemeCatalog`](../lib/services/theme_catalog.dart), in picker order.
Hues are OKLCH degrees.

| id | Hue | Light main | Dark main |
|---|---|---|---|
| `habitt` (default) | 157° | `#02D382` | `#11F29B` |
| `lagoon` | 197° | `#00CBCE` | `#09EAEE` |
| `ocean` | 245° | `#09A3FD` | `#3CACFF` |
| `indigo` | 272° | `#5D73EA` | `#859DFE` |
| `violet` | 302° | `#955FD8` | `#BA86FF` |
| `orchid` | 340° | `#DA62B7` | `#F16BCA` |

Each theme also has a button gradient pair per mode (`buttonLeft`, `buttonRight`).
Theme ids are stored in preferences and must never change once shipped.

## Guardrails

`test/services/theme_catalog_test.dart` enforces these over the whole catalog:

- **Keep clear of the semantic hues.** `main` marks completion. An accent near
  red (`fail`, ~23°) or amber/orange (`mid` and the streak, ~50–71°) would make
  completed items look failed or like a streak. Every accent stays at least 35°
  away in OKLCH. That leaves blue, cyan/teal, violet and magenta; red, orange and
  yellow are not offered.
- **Contrast floors.** White on Habitt's light green is only ~2:1, so a light
  accent may not be lighter than that (at least 1.9:1 against white). Dark accents
  keep at least 4.5:1 against the dark background. Button text keeps its existing
  rule (`cp.bg`), so no per-theme text colour exists.
- **Distinct from the brand.** A theme's light hue must differ from Habitt's by at
  least 25°.
- **Habitt is exact.** The catalog test checks Habitt equals the original
  `Light`/`Dark` constants.

### How the colours were chosen

Matching the brand's lightness exactly (OKLCH L≈0.76 light, 0.85 dark) washes
blues and violets out to pastel, because the mint is vivid at a lightness where
those hues cannot be. So each accent takes the lightness nearest its own chroma
peak, clamped to a band (light 0.60–0.763, dark 0.72–0.85), at the brand's chroma
(about 0.18 light, 0.195 dark). The button gradient keeps the brand's offsets
(right side darker, dark-mode left side lighter).

## Accent-coloured assets

A few SVGs have the brand green baked in (the check marks and the arrow).
[`AccentSvg`](../lib/widgets/default/accent_svg.dart) swaps `#02D382` and
`#11F29B` for the selected accent when the file loads, using `flutter_svg`'s
`ColorMapper`, so no asset is duplicated per theme. The shared
[`Checkmark`](../lib/widgets/default/checkmark.dart) (habit check, "Mark as
complete" button), the status toast, the hold tip, the sync overlay and the
language and sound pickers all use it. SVGs that are drawn with a plain colour
filter need nothing.

Not themed on purpose: `PaywallPage` and the Profile support card artwork stay
Habitt green (`BrandColors` in `color_service.dart`), and a few stat icons have
their own colour identity (`completed.svg`, `increase.svg`, the stat card icons).

The consistency calendar ramp and the weekly completion bars are derived from
`cp.main` (soft alpha steps, the full accent for 100 % or today).

## The picker

[`ThemePicker`](../lib/widgets/settings/theme_picker.dart) shows the themes as
swatch chips drawn in the current light/dark mode, under "Mode" in the Appearance
card. Picking a theme applies it live. The first pick (and then at most every 30
days) also offers the support sheet, see `docs/support_asks.md`. Theme names are
localised (`themeName*` in the ARB files).

## Adding a theme

1. Pick a hue at least 35° from 23° and from 50–71°, at least 25° from Habitt.
   Take lightness near its chroma peak inside the bands above, light and dark.
2. Add an `AppTheme` constant to `ThemeCatalog` and append it to `all`. Never
   reorder or rename existing ids.
3. Add a `themeName<Name>` string at the bottom of **every** ARB file, regenerate
   l10n, and add the case to `_themeName` in `theme_picker.dart`.
4. Run `flutter test test/services/theme_catalog_test.dart`. It fails if the
   hue or contrast rules are broken.

## Legacy

`ThemeProvider`/`OldColorService` (the old accent maps and `accent_name`) are
deprecated and still watched by some older widgets for habit colours. The new
system does not read them. Deleting them is a separate clean-up.

## Maintenance rule

Any change to how themes work, the catalog, the guardrails or which assets follow
the accent must also update this document.
