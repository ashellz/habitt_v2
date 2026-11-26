fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios check_metadata

```sh
[bundle exec] fastlane ios check_metadata
```

Check name/subtitle/keywords/description lengths for every locale (offline)

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Validate, then upload store text only (name, subtitle, keywords, description). No binary, no screenshots, no review submission

### ios internal

```sh
[bundle exec] fastlane ios internal
```

Upload the built IPA to TestFlight with per-locale What's New from release_notes.txt

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit the already-uploaded TestFlight build to App Store review (release notes only)

### ios watch_screenshots

```sh
[bundle exec] fastlane ios watch_screenshots
```

Stage the watch screenshots (all languages) and the en-US iPhone watch slide, then upload them and the store text to the given version (created if needed). Adds screenshots, never deletes. No review submission

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new release build to the App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
