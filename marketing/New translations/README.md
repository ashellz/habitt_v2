# Habitt — Store Localization Pack

18 new locales, generated 16 August 2026 from the fload App Store audit.

```
New translations/
├── README.md                    ← you are here
├── markdown/                    ← human-readable, one file per locale
│   └── app_store_description_<locale>.md
└── fastlane/
    └── metadata/
        ├── <apple-locale>/      ← iOS: name, subtitle, keywords, promo, description
        └── android/
            └── <play-locale>/   ← Play: title, short_description, full_description
```

---

## First: a correction to the audit

The report treats **47 storefronts as 47 translation jobs**. They aren't. App Store
metadata is stored **per language**, and each storefront serves whichever localization
matches the user's device language.

| Audit says | Reality |
|---|---|
| Belgium has no localization | Belgium isn't a language. It reads `fr-FR` and `nl-NL` — both included here. |
| France, Switzerland, Luxembourg, Monaco | All read one `fr-FR` file. |
| Portugal and Brazil | Genuinely separate (`pt-PT` / `pt-BR`). Both included. |
| China, Taiwan, Hong Kong | `zh-Hans` + `zh-Hant`. Both included. |

Your 47 storefronts collapse to roughly **20 useful locales**. You had 5. This pack
adds 18, which covers every market in the audit's appendix that carries meaningful
iOS revenue.

Apple currently declares 50 metadata locales, but ~11 of the March 2026 additions
(Bangla, Marathi, Slovenian, Tamil, Telugu, Punjabi, Urdu) still error out in App
Store Connect. The practical ceiling is **39**.

---

## Priority order — do these in this sequence

### 0. Two things before any translation (30 minutes, highest ROI in the whole audit)

1. **Fill the promotional text field.** The audit flags it as empty (0/170). You
   already wrote it — it's sitting in `app_store_description_en.md` in the parent
   folder. It's the only listing field that changes without shipping a build.
2. **Add `en-GB`, `en-AU`, `en-CA`.** Zero translation. See "How the English
   locales actually work" below — they do less than the audit implies, but `en-GB`
   reaches more storefronts than its name suggests. Files are in this pack.

### 1. The nine US cross-indexed locales ← the audit's finding #1

The US storefront does not index only `en-US`. Apple cross-indexes **10 locales**
for US search, on the assumption that US residents speak them:

`en-US` · `es-MX` · `pt-BR` · `ru` · `ko` · `zh-Hans` · `zh-Hant` · `ar` · `vi` · `fr-CA`

Every one of those nine secondaries carries its own 30-char Name, 30-char Subtitle
and 100-char keyword field — **all indexed for US searches**. That's the "unused
secondary US locales" gap in the report, and it's worth roughly 1,300 additional
indexed characters in your single most valuable storefront.

All nine are in this pack, each with a keyword set built for double duty: it has to
work for the native market *and* pull weight in the US.

### 2. Remaining Tier 1 markets

`fr-FR` · `pt-PT` · `nl-NL` · `ja` · `tr` · `pl`

Large storefronts currently serving your English listing with no local-language
indexing at all.

---

## How the English locales actually work

**They do not stack.** This is the part it is easy to get wrong.

Each storefront indexes a **primary locale**. The UK storefront's primary English
locale is `en-GB`. Today you have no `en-GB`, so the UK falls back to your primary
language (`en-US`) and indexes *that*. Adding `en-GB` **replaces** which field set
the UK indexes — it does not add a second one. Australia works the same way.

So adding `en-GB` and `en-AU` does **not** buy you extra keyword characters. Each
English storefront still gets exactly 30 + 30 + 100.

**Canada is the exception.** It indexes `en-CA` **and** `fr-CA` together. That is
the only English storefront where you genuinely get two field sets — which is why
the `fr-CA` file matters more than its market size suggests.

### What they are actually worth

1. **Reach.** `en-GB` is the English locale most non-US storefronts fall back to.
   It likely serves Ireland, Singapore, India, South Africa, Philippines, Malaysia
   and Hong Kong on top of the UK — roughly 10 of your 47 storefronts.
2. **Spelling.** Apple does not stem `wellbeing` ↔ `wellness` or `organise` ↔
   `organize`. Commonwealth spelling is real, separate coverage.
3. **Independence.** You can tune `en-US` for US demand without dragging the UK
   listing along with it.

### Why the Name and Subtitle are identical in all four

Because they don't stack, each English storefront gets exactly one name. If
`Habitt: Private Habit Tracker` is your best 30 characters — and at 29/30 with brand
plus the category's highest-volume phrase, it is — then shipping any other name to
the UK, Australia or Canada means deliberately running a weaker variant there in
exchange for nothing.

The same argument applies to the Subtitle, so all four carry
`Routines, Goals & Streaks`, matching your live `en-US` listing exactly.

**A/B testing across these storefronts is not a reason to diverge.** At your current
rating volume you will never reach significance, and in the meantime three of the
four markets run a listing you judged second-best.

### What does differ, and why

| Locale | Name | Subtitle | Keywords |
|---|---|---|---|
| `en-GB` | same | same | `wellbeing` (British spelling) |
| `en-AU` | same | same | byte-identical to `en-GB` |
| `en-CA` | same | same | **differs** — see below |

`en-AU` being identical to `en-GB` is the correct answer, not laziness: separate
storefronts, one indexed English locale each, so both should carry your best set.

`en-CA` is the only one that legitimately diverges. Since Canada indexes `en-CA`
and `fr-CA` together, `discipline` and `journal` — spelled identically in both
languages — were dropped from the English field because `fr-CA` already carries
them. Apple counts a word once per territory, so keeping both copies would waste
19 characters. Those went to `calendar`, `checklist` and `focus`, which `fr-CA`
does not cover. The generator now checks this collision automatically.

### One thing to consider for `en-US`

Your live `en-US` subtitle is 25/30 and its keyword field predates this pass. If
you ever want to change either, change **all four English locales together** —
that is the whole point of keeping them aligned.

---

## Answering your two questions

### Q1 — do you have to click through each language in App Store Connect?

**No.** Use `fastlane deliver`. The `fastlane/` folder in this pack is already in
the exact structure it expects — drop it into your `habitt_v2` repo root and run:

```bash
# iOS — uploads every locale's metadata in one command
fastlane deliver \
  --skip_binary_upload true \
  --skip_screenshots true \
  --force                       # skips the HTML confirmation preview

# Android
fastlane supply \
  --skip_upload_apk true \
  --skip_upload_aab true \
  --skip_upload_images true
```

One command, all 23 locales. Never open App Store Connect for metadata again.

Two setup notes:

- **Auth**: use an App Store Connect API key (`.p8`), not your Apple ID — it avoids
  2FA prompts in CI. Set `FASTLANE_API_KEY_PATH` or use the `app_store_connect_api_key`
  action.
- **`default/` folder**: fastlane supports a special `metadata/default/` locale for
  fields identical across every language. Your support and marketing URLs belong
  there rather than repeated 23 times.

The alternative is the App Store Connect API directly
(`POST /v1/appStoreVersionLocalizations`). Same result, more code. No reason to.

### Q2 — do you have to translate the changelog for every update, forever?

**App Store: yes, and it matters.** Every localization needs its own "What's New".
If you skip a locale, the *previous version's* release notes stay live for those
users — worse than English, because it describes features that already shipped.

**Play Store: no.** Play falls back to your default language when a locale has no
changelog for that version code.

The workflow that makes this a 5-minute job instead of an afternoon:

1. Write the English changelog once.
2. Ask me to translate it into all 23 locales — I write directly into
   `fastlane/metadata/<locale>/release_notes.txt` and
   `fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt`.
3. Run the two `fastlane` commands above.

The `translate` skill already installed in this project covers HR/IT/DE/ES. Worth
extending it to the full locale list so step 2 becomes a single slash command.

Keep release notes **short and generic** — 2–4 bullets, no idioms, no wordplay.
That keeps translation cheap and avoids the localization becoming a bottleneck on
shipping.

---

## Locale reference

| Apple | Play | Language | Storefronts | US-indexed |
|---|---|---|---|:---:|
| `es-MX` | `es-419` | Español (México) | Mexico | ✅ |
| `pt-BR` | `pt-BR` | Português (Brasil) | Brazil | ✅ |
| `ru` | `ru-RU` | Русский | Russia | ✅ |
| `ko` | `ko-KR` | 한국어 | South Korea | ✅ |
| `zh-Hans` | `zh-CN` | 简体中文 | China mainland | ✅ |
| `zh-Hant` | `zh-TW` | 繁體中文 | Taiwan, Hong Kong, Macau | ✅ |
| `ar-SA` | `ar` | العربية | Saudi Arabia, UAE, Egypt, Qatar, Kuwait | ✅ |
| `vi` | `vi` | Tiếng Việt | Vietnam | ✅ |
| `fr-CA` | `fr-CA` | Français (Canada) | Canada (fr) | ✅ |
| `en-GB` | `en-GB` | English (U.K.) | UK, Ireland + English fallback for SG, IN, ZA, PH, MY, HK | |
| `en-AU` | `en-AU` | English (Australia) | Australia, New Zealand | |
| `en-CA` | `en-CA` | English (Canada) | Canada (en) — **stacks with `fr-CA`** | |
| `fr-FR` | `fr-FR` | Français | France, Belgium (fr), Switzerland (fr), Luxembourg | |
| `pt-PT` | `pt-PT` | Português (Portugal) | Portugal | |
| `nl-NL` | `nl-NL` | Nederlands | Netherlands, Belgium (nl) | |
| `ja` | `ja-JP` | 日本語 | Japan | |
| `tr` | `tr-TR` | Türkçe | Türkiye | |
| `pl` | `pl-PL` | Polski | Poland | |

Already live, not in this pack: `en-US`, `de-DE`, `es-ES`, `it`, `hr`.

---

## How the keyword fields were built

Apple merges Name + Subtitle + Keywords into **one index per locale**, and counts
each word **once**. Repeating a word across fields wastes characters and gains
nothing. So in every file:

- No keyword repeats a word already in that locale's Name or Subtitle.
- Keywords are comma-separated with **no spaces** — a space after a comma costs a
  character and buys nothing.
- Diacritics are stripped in the keyword field for `fr`, `pt`, `vi`, `tr`, `pl`.
  Mobile users type unaccented queries far more often than accented ones, and Apple
  does not reliably stem one to the other. Names, subtitles and descriptions keep
  full diacritics — those are read by humans.
- Locale-native terms with no English equivalent are included deliberately:
  `갓생` (KR), `打卡` (CN/TW), `صلاة` (AR), `namaz` (TR), `academia` (BR).

Every field was verified programmatically against Apple's limits, plus two
structural checks: no keyword may repeat a word from its own Name or Subtitle
(substring match, so CJK is covered too), and `en-CA` may not repeat anything
`fr-CA` already indexes. Current usage: Names 13–29/30, Subtitles 11–28/30,
Keywords 90–99/100, Promo text 70–169/170, Play short descriptions 33–80/80.

The CJK locales look "short" in character terms because Chinese, Japanese and
Korean carry far more meaning per character — those fields are dense, not empty.

---

## One thing to watch

Your app UI ships in **English, German, Spanish, Italian, Bosnian**. Fourteen of
these 18 locales have no matching UI language.

That's a normal and legitimate ASO play, but at **1 total rating** you have no
buffer to absorb "the app isn't in my language" one-star reviews. Every affected
description therefore ends with a one-line disclosure naming the supported UI
languages, in that language. It costs ~80 characters of a 4,000-character field.

The four locales *without* the disclosure are `en-GB`, `en-AU`, `en-CA` (English UI
exists) and `es-MX` (Spanish UI exists).

If you'd rather remove it, it's the final paragraph of every `description.txt` —
easy to strip. My recommendation is to leave it until you're past ~50 ratings.

---

## Sources

- [App Store localizations — Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations/)
- [App Store expands support to 11 new languages — Apple Developer News](https://developer.apple.com/news/?id=97t4mt64)
- [App Store cross-localization: territory-level keyword indexation — MobileAction](https://www.mobileaction.co/blog/app-store-cross-localization/)
- [App Store Localization: Primary and Secondary Languages — AppTweak](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store)
- [upload_to_app_store (deliver) — fastlane docs](https://docs.fastlane.tools/actions/upload_to_app_store/)
- [App Store Languages: All 39 Locales & Character Limits — StoreTranslate](https://storetranslate.com/app-store-languages/)
