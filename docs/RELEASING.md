# Releasing

Releases are built and shipped by GitHub Actions. iOS and Android share one
release number: one draft GitHub release carries both signed artefacts, and
publishing that release sends them to the stores' internal testing tracks.
Every command below is `./bin/na …`; CI and local runs use the same code path.

## Two-phase flow

| Workflow | Trigger | What it does |
|---|---|---|
| Draft release candidate (`release-draft.yml`) | manual (`workflow_dispatch`: `bump` patch/minor/major/none, optional `version`, `build`, `previous_tag`, `prerelease`) | `./bin/na release version x.y.z --build n`, commits and tags, drafts a GitHub release with generated notes, builds the signed `.aab` (ubuntu) and `.ipa` (macos) from the tag and attaches both |
| Publish release to stores (`release-publish.yml`) | the release goes draft → published | Downloads the artefacts from the release (no rebuild) and runs `./bin/na publish play --aab …` and `./bin/na publish testflight --ipa …` |

Internal testing only. Nothing is submitted for review; promotion to
closed/open testing or production is a manual store-console action.

1. Actions → Draft release candidate → choose bump or type a version → Run.
2. Wait for the draft with `nadanmark-<version>-<build>.aab` and `.ipa`.
3. Edit the notes; the text between the `release-notes` markers goes to Google
   Play when `PLAY_RELEASE_NOTES_LANGUAGE` is set. TestFlight "What to Test" is
   written in App Store Connect.
4. Publish the release. Uploads start automatically.

A failed build leaves the draft in place: delete the draft and its tag, fix,
rerun. Nothing is signed or uploaded before you publish.

## Version numbering

`./bin/na release version <x.y.z> [--build n]` is the only thing that writes
version numbers. It updates `app/pubspec.yaml` (`version: x.y.z+<versionCode>`),
the Android `versionCode`/`versionName` and the iOS
`CFBundleShortVersionString`/`CFBundleVersion` so they never drift.

- Android `versionCode = 1100000000 + (major*10000 + minor*100 + patch) * 1000 + build`.
  First Flutter release 2.0.0 build 1 → `1120000001`. The legacy Ionic app's
  last code was `1110300001` (1.3.0 build 1), so every Flutter code is above it
  and all stay below Play's `2100000000` ceiling.
- iOS `CFBundleVersion = build`. TestFlight needs a new build number for every
  upload of the same version, so raise `--build` to re-release a version.
- Git tag: `x.y.z` for build 1, `x.y.z-bN` for build N > 1.

`./bin/na release check` verifies that the three places agree and that the
code is above the legacy ceiling.

## Secrets

Repository → Settings → Secrets and variables → Actions → Secrets:

| Secret | What it is |
|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Maps + Places key, written into `env/release.json` at build time. Optional per-platform overrides: `GOOGLE_MAPS_ANDROID_API_KEY`, `GOOGLE_MAPS_IOS_API_KEY`. |
| `NA_API_BASIC_AUTH` | `user:password` for the nadanmark.dk API (events, speaks). |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 keys/nadanmarkapp.keystore` (the existing upload key) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_PASSWORD` | key password (usually the same) |
| `ANDROID_KEY_ALIAS` | optional, defaults to `nadanmarkapp` |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account key (whole JSON, or base64 of it) |
| `IOS_DIST_CERT_BASE64` | base64 of a `.p12` holding the Apple Distribution certificate and its private key (an older `iPhone Distribution` certificate also works; `IOS_CODE_SIGN_IDENTITY` can override the identity) |
| `IOS_DIST_CERT_PASSWORD` | password used when exporting that `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | base64 of the App Store `.mobileprovision` for `dk.nadanmark.ios.app`; the release build signs manually |
| `IOS_TEAM_ID` | Apple Developer team id (10 characters) |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key id |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer id |
| `APP_STORE_CONNECT_PRIVATE_KEY` | contents of `AuthKey_XXXXXXXX.p8` or base64 of it (CRLF and `\n` escapes accepted) |
| `RELEASE_APP_PRIVATE_KEY` | private key of the GitHub App that pushes the version-bump commit and tag |
| `FTL_SERVICE_ACCOUNT_JSON` | Firebase service account key with the Cloud Testing API role, used by the nightly real-device E2E run |

Variables (same page, Variables tab; not secret):

| Variable | Default | Purpose |
|---|---|---|
| `PLAY_RELEASE_NOTES_LANGUAGE` | unset | e.g. `da-DK`. Play rejects notes for a language the listing lacks, so notes are only sent when set. |
| `XCODE_VERSION` | runner default | Pin Xcode, e.g. `16.4`, if the default image breaks the build. |
| `RELEASE_APP_ID` | — | Id of the GitHub App used for the version-bump commit. |
| `FTL_PROJECT_ID` | — | Firebase project id for Firebase Test Lab. |

Legacy variables `PLAY_CLOSED_TESTING`, `PLAY_CLOSED_TRACK`, `PLAY_TRACKS`,
`TESTFLIGHT_INTERNAL_GROUP` are not read; delete them if present.

The Actions token needs Settings → Actions → General → Workflow permissions →
Read and write, and `github-actions[bot]` (or the release app) must be allowed
to push to `master` if it is protected.

## Producing the credentials, once

```
# Android keystore
base64 -w0 keys/nadanmarkapp.keystore                 # Linux
base64 -i keys/nadanmarkapp.keystore | tr -d '\n'     # macOS

# iOS distribution certificate: Keychain Access -> right-click the private key
# of "Apple Distribution: ..." -> Export -> .p12
base64 -i dist-cert.p12 | tr -d '\n'

# iOS provisioning profile: developer.apple.com -> Profiles -> App Store profile
# for dk.nadanmark.ios.app -> Download
base64 -i NA_Danmark_App_Store.mobileprovision | tr -d '\n'

# Firebase Test Lab service account
base64 -w0 ftl-service-account.json
```

Google Play service account: Play Console → Users and permissions → invite the
service account with "Release to testing tracks" and "View app information" on
`dk.nadanmark.app`. The JSON key comes from the linked Google Cloud project
(IAM → Service accounts → Keys).

App Store Connect API key: App Store Connect → Users and Access → Integrations →
App Store Connect API → team key with the App Manager role. The `.p8` downloads
once.

Firebase Test Lab: Firebase console → Project settings → Service accounts →
generate a key; grant it "Firebase Test Lab Admin" and "Cloud Storage Object
Viewer" in IAM.

## Running a release build locally

The same commands run locally but refuse to act unless every condition is met:
all credentials in the environment, signing material present, a clean git
worktree (`--allow-dirty` to override) and agreeing version numbers.

```
./bin/na release check              # what is missing?
./bin/na release check android
./bin/na release android --dry-run  # print the steps
./bin/na release android            # signed .aab into dist/
./bin/na release ios                # signed .ipa into dist/ (macOS only)
./bin/na publish play --aab dist/nadanmark-2.0.0-1.aab --yes
./bin/na publish testflight --ipa dist/nadanmark-2.0.0-1.ipa --yes
```

`na publish` requires `--yes` outside CI because it pushes to real testers.
Credentials are written to `env/release.json`,
`app/ios/Flutter/Secrets.xcconfig` and `app/android/key.properties` right
before the build and deleted right after; all three are git-ignored.

## Notes

- iOS builds run on `macos-15`; macOS minutes are free because the repository is public.
- `ITSAppUsesNonExemptEncryption = false` is set in `Info.plist` (HTTPS only), so App Store Connect does not hold builds for an export compliance answer.
- The first Flutter release must be tested as an update over the last Ionic build: install the old APK/IPA, use the app (set a clean date, listen to a chapter), install the new build, verify the imported data on the Contact page and in the Cleantime calculator.
