# NA Danmark App

The mobile app of Narcotics Anonymous Danmark: meeting list, meetings nearby,
map, "Just for Today", cleantime calculator, events, audiobooks, speaks and
group readings. Danish and English. iOS and Android.

- App Store: https://apps.apple.com/dk/app/na-danmark/id6739226092
- Google Play: https://play.google.com/store/apps/details?id=dk.nadanmark.app

This repository is the Flutter rewrite. The Ionic/Cordova app that is in the
stores today lives in the `App` repository and stays there until this app
reaches feature parity (`docs/LEGACY_PARITY.md`); the rewrite ships under the
same store ids and imports the old app's data on first start.

## Quick start

```
git clone https://github.com/Narcotics-Anonymous-Danmark/NADanmarkApp.git
cd NADanmarkApp
./bin/na bootstrap
./bin/na run
```

Prerequisites on the machine: [fvm](https://fvm.app) (or Flutter at the version
pinned in `.fvmrc` on `PATH`), a JDK 17 and, for Android, an SDK reachable
through `ANDROID_HOME`. `./bin/na` picks the pinned Flutter through fvm and
installs it when missing; `./bin/na bootstrap` verifies Flutter and the JDK,
then installs the Android command-line tools, platform, emulator and AVD
(CocoaPods on macOS), lcov, the Patrol CLI and the git hooks. `./bin/na doctor`
reports the same checks read-only, including the Linux inotify limits the Dart
analysis server needs.

## Commands

| Command | What it does |
|---|---|
| `./bin/na bootstrap [android\|ios]` | Install everything, idempotent |
| `./bin/na doctor` | Verify the environment |
| `./bin/na run [android\|ios] [--device\|--emulator\|--target id]` | Build and run |
| `./bin/na test [unit\|widget\|acceptance\|e2e\|all] [--coverage]` | Run a test level |
| `./bin/na coverage --merge --html --check` | Merge lcov, render HTML, enforce floors |
| `./bin/na check` | Format, analyze, custom lints, ARB parity, dependency layers, spec/test parity |
| `./bin/na gen [l10n\|all]` | Generate localisations |
| `./bin/na release version x.y.z [--build n]` | The only way to change version numbers |
| `./bin/na release check\|android\|ios` | Signed store builds |
| `./bin/na publish play\|testflight` | Upload to internal testing |

Never call `flutter`, `dart`, `gradle` or `pod` directly; `./bin/na` is the one
code path for local runs and CI.

## Architecture

Hexagonal Flutter: `na_kernel` (value types, sealed results, pure logic) ←
`na_ports` (interfaces with throwing Riverpod providers) ← one feature package
per capability and one adapter package per external system ← `app/` (the
composition root that builds the `ProviderContainer`). Widgets layer only, no
Material; design tokens and primitives in `na_design`; ARB localisation in
`na_l10n`; builders, mimics and fake time in `na_testing`. Behaviour is
specified in `openspec/specs/` and every scenario there is an acceptance test.
Details: `docs/ARCHITECTURE.md`.

## Documentation

| Document | Content |
|---|---|
| `AGENTS.md` | How to work in this repo (humans and AI agents) |
| `CONTRIBUTING.md` | Setup, branches, commits, OpenSpec workflow, PR checklist |
| `docs/CODING_GUIDELINES.md` | Every rule with its lint |
| `docs/ARCHITECTURE.md` | Layers, packages, Riverpod wiring, types policy |
| `docs/TESTING.md` | Four test levels, builders, mimics, coverage |
| `docs/RELEASING.md` | Two-phase release flow, version numbers, secrets |
| `docs/LEGACY_PARITY.md` | Legacy route, storage key, i18n key and plugin mapping |
| `openspec/project.md` | Purpose, stack, glossary |
| `openspec/specs/<capability>/spec.md` | The behaviour contract per capability |

## Licence and trademarks

The NA logo is a registered trademark of NA World Services and is used in
accordance with the Fellowship Intellectual Property Trust. "Just for Today"
texts are copyright NA World Services, Inc.
