fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android check_metadata

```sh
[bundle exec] fastlane android check_metadata
```

Check title/short/full description lengths for every locale (offline)

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Validate, then upload the store listing text only (title, short and full description) for all locales

### android test

```sh
[bundle exec] fastlane android test
```

Runs all the tests

### android beta

```sh
[bundle exec] fastlane android beta
```

Submit a new Beta Build to Crashlytics Beta

### android internal

```sh
[bundle exec] fastlane android internal
```

Upload the built AAB to the Play internal testing track with per-locale changelogs

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote the internal track build to production

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy a new version to the Google Play

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
