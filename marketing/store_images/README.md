# Store images (App Store / Google Play)

Localized marketing images for both stores, in every app language
(en, bs, de, es, fr, it, pt, tr). Output goes to `out/<ios|android>/<lang>/NN_name.png`
(ignored by git; re-render any time).

| # | iOS (1290×2796) | Android |
|---|---|---|
| 01 | Build habits (Figma) | Build habits (Figma, 1080×1920) |
| 02 | Track your way (Figma) | Track your way (Figma) |
| 03 | Consistency (Figma) | Consistency (Figma) |
| 04 | Reminders (Figma) | Reminders (Figma) |
| 05 | Private / offline (slide) | Private / offline (slide) |
| 06 | Apple Health (slide) | Health Connect (slide) |
| 07 | Themes (slide, iOS only) | Any mood (Figma) |
| 08 | Any mood (Figma) | Wear OS (slide) |
| 09 | Apple Watch (slide) | |

The order lives in `IOS_ORDER` / `PLAY_ORDER` in `render.mjs`.

## Sources

- **Figma** — file *Habit Tracker (Copy)*, page *App Store, Google Play Screenshots*.
  The section *Localization base (text hidden)* holds a copy of the 5 App Store and
  5 Play frames with every translatable text layer at 0% opacity (the notch is also
  hidden on the last Play frame). Exported to `base/<frameId>.png`.
  `figma_text.json` has each of those text layers' position, size, style, clip and mask,
  extracted from the original frames. The renderer draws the translated text back on top
  in Satoshi.
- **Slides** (`slides.mjs`) — the 6 extra slides (Private, Apple Health / Health Connect,
  Themes, Apple Watch / Wear OS), built on the Figma frames' tokens (inset card, Bold
  headline, Regular subtitle, app-style habit cards) with the app's own icons
  (`assets/images/health-icons`, check-on/off, the progress pie from
  `new_habit_progress.dart`). Each slide's content is laid out once and scaled into the
  room under the headline, so Play gets a real 1080×1920 version. The *Habitt Store
  Screenshots* design canvas shows the English versions.
- **Watch screens** — `watch_composite.py` puts each language's real watch screenshot
  (`marketing/watch_screenshots/<watchos|wear_os>/<lang>`) into the watch bezels in
  `assets/`, written to `build/watch/<lang>/`.
- **Text** — `translations.json` (English → each language). UI labels follow the app's
  ARB wording.

## Render

```bash
marketing/store_images/build.sh
```

Needs Google Chrome (headless) and Python 3 (it sets up a venv with Pillow + numpy).
Open `out/index.html` to see every image. Steps: watch screens → English → `occlusion.py` (finds text layers that a card covers in
the original design, by comparing with `assets/figma_section_*.png`) → `baked.py` (finds
English that Figma left visible in the text-hidden export, mostly inside component
instances, and records the colour to paint over it) → all languages.
Every translated text is shrunk until it fits the space the English text used (headlines
keep their English line count), so check new or longer translations visually.

### How Figma text is redrawn (render.mjs)

- Single-line app labels end in "…" like the app; labels in pills and day circles first
  shrink to 75%. Headlines and subtitles shrink to keep the English line count.
- `CENTERED` / `WEEKDAYS`: labels Figma centres through their parent grow evenly to both
  sides, stopping at neighbours (e.g. the edit icon next to "Habit details").
- `ALSO_HIDDEN`: layers peeking out behind the enlarged reminder card.
- `CHIP`: the tilted "Mark as complete" chip is redrawn per language (white pill, the app's
  `check-on-light.svg`), so it must be hidden in the *Build habits* bases.

## Refreshing the Figma bases

After changing a frame in Figma: re-copy it into the *Localization base* section, set the
translatable text layers' opacity to 0, export the 10 frames as PNG 1x into `base/`
(filenames are normalized from the `[id]` in the frame name), and re-extract
`figma_text.json` if text moved.
