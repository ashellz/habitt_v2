# Deploying metadata + changelogs with fastlane

23 locales, both stores, two commands. Written for a Flutter repo (`habitt_v2`).

---

## ⚠️ Read this first

**fastlane overwrites App Store Connect fields with whatever is in the file — including
an empty one.** An empty `description.txt` wipes your live description. This is
long-standing, known fastlane behaviour, not a bug you can configure away.

Two consequences:

1. Never commit an empty `.txt` into the metadata tree. The generators in this pack
   now refuse to write empty files, and the last run confirmed **0 empty files**.
2. **Run the first deploy without `--force`.** Without it, `deliver` renders an HTML
   preview of every field in every locale and waits for your confirmation. Look at
   it. Only add `--force` once you've seen it do the right thing.

The five locales you already have live (`en-US`, `de-DE`, `es-ES`, `it`, `hr`) contain
**only** `release_notes.txt` in this pack — no `description.txt`, no `name.txt`. Missing
files are skipped, so your existing listing text for those five is not touched.

---

## 1. Where the files go

Flutter keeps two separate fastlane setups. Split this pack accordingly:

```bash
cd /path/to/habitt_v2

# iOS
mkdir -p ios/fastlane
rsync -av --exclude 'android' \
  "New translations/fastlane/metadata/" \
  ios/fastlane/metadata/

# Android
mkdir -p android/fastlane/metadata
rsync -av \
  "New translations/fastlane/metadata/android/" \
  android/fastlane/metadata/android/
```

Result:

```
habitt_v2/
├── ios/fastlane/metadata/
│   ├── en-GB/  name.txt subtitle.txt keywords.txt
│   │           promotional_text.txt description.txt release_notes.txt
│   ├── ja/     …
│   └── en-US/  release_notes.txt          ← only this, by design
└── android/fastlane/metadata/android/
    ├── en-GB/  title.txt short_description.txt full_description.txt
    │           changelogs/default.txt
    └── ja-JP/  …
```

---

## 2. One-time setup

### Install

```bash
cd ios     && bundle init && bundle add fastlane && bundle exec fastlane init
cd ../android && bundle init && bundle add fastlane && bundle exec fastlane init
```

### Auth — use an API key, not your Apple ID

An App Store Connect API key avoids 2FA prompts. Generate it at
**App Store Connect → Users and Access → Integrations → App Store Connect API**,
download the `.p8` **once** (it is not downloadable twice), and store it outside the repo.

`ios/fastlane/Appfile`:

```ruby
app_identifier "com.yourcompany.habitt"   # your bundle ID
```

`ios/fastlane/Fastfile`:

```ruby
lane :metadata do
  app_store_connect_api_key(
    key_id:      ENV["ASC_KEY_ID"],
    issuer_id:   ENV["ASC_ISSUER_ID"],
    key_filepath: ENV["ASC_KEY_PATH"]     # path to the .p8
  )
  deliver(
    skip_binary_upload: true,
    skip_screenshots:   true,
    skip_app_version_update: false,
    precheck_include_in_app_purchases: false
  )
end
```

For Play, create a service account in Google Cloud, grant it access in
**Play Console → Users and permissions**, download the JSON key, then
`android/fastlane/Appfile`:

```ruby
json_key_file "/secure/path/play-store-key.json"
package_name  "com.yourcompany.habitt"
```

**Add both key paths to `.gitignore`.** Never commit them.

---

## 3. The commands

### App Store — all 23 locales, listing text + changelog

```bash
cd ios

# FIRST RUN — shows an HTML preview, waits for you to confirm
bundle exec fastlane deliver \
  --skip_binary_upload true \
  --skip_screenshots true

# once you trust it
bundle exec fastlane deliver \
  --skip_binary_upload true \
  --skip_screenshots true \
  --force
```

### Play Store — all 23 locales, listing text + changelog

```bash
cd android

bundle exec fastlane supply \
  --skip_upload_apk true \
  --skip_upload_aab true \
  --skip_upload_images true \
  --skip_upload_screenshots true \
  --version_code 42          # ← your actual versionCode
```

**`--version_code` is required for changelogs.** `supply` matches
`changelogs/<versionCode>.txt` first and falls back to `changelogs/default.txt`.
This pack ships `default.txt`, so any version code works — but supply still needs to
be *told* the code, and a release with that code must already exist in the track.

If you only want to push listing text and no changelog, add
`--skip_upload_changelogs true` and drop `--version_code`.

---

## 4. Per-release workflow from now on

1. Write the English changelog. Keep it short — 2 to 4 lines, no idioms, no wordplay.
   Short generic notes are cheap to translate and never become the thing blocking a release.
2. Ask me to translate it. I write straight into
   `ios/fastlane/metadata/<locale>/release_notes.txt` and
   `android/fastlane/metadata/android/<locale>/changelogs/default.txt`.
3. Run the two commands above.

Realistically five minutes per release once the keys are set up.

**Do not skip a locale.** On the App Store, a localization with no new release notes
keeps serving the *previous* version's text — describing features that already
shipped. That's worse than English. Play falls back to your default language, so it's
less critical there.

---

## 5. First-deploy order

Adding a brand-new localization to App Store Connect requires at minimum a name and
a description for it, which is why the 18 new locales ship with full field sets.

1. Run `deliver` **without** `--force` and read the HTML preview end to end.
2. Confirm the 18 new locales appear with the right name, subtitle and description.
3. Check the Arabic listing renders RTL correctly in App Store Connect.
4. Submit. Metadata-only changes are usually reviewed within hours.

---

## Sources

- [upload_to_app_store (deliver) — fastlane docs](https://docs.fastlane.tools/actions/upload_to_app_store/)
- [supply — fastlane docs](https://docs.fastlane.tools/actions/supply/)
- [Empty metadata files should not overwrite iTunes Connect content — fastlane #9764](https://github.com/fastlane/fastlane/issues/9764)
- [Cannot find changelog because no version code given — fastlane #15681](https://github.com/fastlane/fastlane/issues/15681)
