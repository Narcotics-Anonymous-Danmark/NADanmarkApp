# AGENTS.md

Guidance for AI agents and humans working in this repository.

## What this is

The NA Danmark mobile app (iOS + Android) rewritten in Flutter/Dart. It replaces the
Ionic/Cordova app in the sibling repo `../App`, feature by feature, under the same
store ids `dk.nadanmark.app` (Android) and `dk.nadanmark.ios.app` (iOS). The legacy
app is the behavioural reference; `openspec/specs/` is the contract.

## Repo map

| Path | Purpose |
|---|---|
| `app/` | The Flutter app: composition root, router, native runners, acceptance tests (`test_acceptance/`) and Patrol E2E (`integration_test/`) |
| `packages/core/na_kernel` | Value types, sealed results, `LocalDate`, `Clock`/`Ticker`/`Scheduler`, `EventBus` |
| `packages/core/na_ports` | Port interfaces and their (throwing) Riverpod providers |
| `packages/core/na_design` | Design system on Flutter's widgets layer, no Material/Cupertino |
| `packages/core/na_l10n` | ARB files (`app_en.arb`, `app_da.arb`) and generated localisations |
| `packages/core/na_testing` | Builders, mimics, fake time, `TestContainer` |
| `packages/features/*` | One package per capability: use cases + widgets |
| `packages/adapters/*` | One package per external system implementing ports |
| `tool/na_cli` | The Dart CLI behind `./bin/na` |
| `tool/na_lints` | Custom lint rules enforcing the guidelines |
| `openspec/` | Specs (truth) and changes (proposals) |
| `docs/` | Architecture, guidelines, testing, releasing, legacy parity |
| `env/` | `--dart-define-from-file` inputs; `release.json` is never committed |

## Workflow

1. Read `docs/CODING_GUIDELINES.md` and the spec for the capability in `openspec/specs/<capability>/spec.md`.
2. Propose a change: `/opsx:propose <slug>` creates `openspec/changes/<slug>/` with proposal, spec deltas and tasks. Get it reviewed.
3. Implement with `/opsx:apply`, in this order: domain types → ports → mimics/builders → acceptance tests (red) → use cases → widgets → real adapter → one Patrol happy path.
4. Every `#### Scenario:` in the spec becomes an acceptance test with the scenario name as its description.
5. Run `./bin/na check && ./bin/na test unit widget acceptance --coverage` before declaring done. Coverage floors are in `coverage.yaml`.
6. Open a PR titled with a conventional commit (`feat(meetings): ...`). After merge, `/opsx:archive` folds the deltas into `openspec/specs/`.

## Rules in one screen

- No comments. No nullable types. No `!`. No `bool` declarations. No `_` or `default` in switches.
- Absence is a sealed class with a domain name, never `Option<T>`.
- `extension type const` for every domain value (ids, keys, URLs, names, texts, codes, measures); no bare primitives in domain classes.
- No vague types (`Object`, `dynamic`, `List<(Object, Object)>`) anywhere, tests included.
- JSON only through `json_serializable`: lenient, all-nullable wire DTOs in generated `part` files (`./bin/na gen json`), validated and mapped to domain types right away.
- Exact dependency versions only (no `^`); internal packages are `version: 0.0.0`.
- Generated code (l10n, JSON) only via `./bin/na gen`; never hand-written.
- Prefer established libraries over hand-rolled algorithms; no README files in random folders.
- Functional collection operations; unmodifiable results.
- Named parameters everywhere; no default values outside tests.
- Time only through `Clock`, `Ticker`, `Scheduler`; never `DateTime.now()` or `Timer`.
- Hexagonal: kernel ← ports ← features/adapters ← app. Features never import adapters.
- Riverpod with an explicit `ProviderContainer`; no singletons or static state.
- Widgets layer only; small `const` widgets; `StatefulWidget` only in `na_design/.../flutter_bridge`.
- Cross-feature communication through `EventBus`; adapters expose `Stream`s.
- English strings in code and specs; every user-facing string in both ARB files.
- Tests: pure, builder-based, mimics at the wire, shared setup in `test/support/`.

`docs/CODING_GUIDELINES.md` has the good/bad example for each rule and names the lint that enforces it.

## Commands

| Command | What it does |
|---|---|
| `./bin/na bootstrap [android\|ios]` | Install everything (tools, Android SDK, AVD, CocoaPods) idempotently |
| `./bin/na doctor` | Verify the environment |
| `./bin/na run [android\|ios] [--device\|--emulator\|--target id]` | Build and run |
| `./bin/na test [unit\|widget\|acceptance\|e2e\|all] [--coverage]` | Run a test level |
| `./bin/na coverage --merge --html --check` | Merge lcov, render HTML, enforce floors |
| `./bin/na check` | Format, analyze, custom lints, ARB parity, dependency layers |
| `./bin/na gen [l10n\|all]` | Generate localisations |
| `./bin/na release version x.y.z [--build n]` | The only way to change version numbers |
| `./bin/na release check\|android\|ios` | Signed store builds |
| `./bin/na publish play\|testflight` | Upload to internal testing (CI, or `--yes` locally) |

Never call `flutter`, `dart`, `gradle` or `pod` directly for project tasks; go
through `./bin/na` so local runs and CI use the same code path.

## Must not

- Import `package:flutter/material.dart` or `cupertino.dart` anywhere.
- Add a dependency from a feature to an adapter, or from any package to `app/`.
- Commit `env/release.json`, `Secrets.xcconfig`, keystores or `.na-release/`.
- Change version numbers by hand.
- Add translations to only one ARB file.
- Write a hand-rolled JSON parser, a version range (`^`), or a README outside `docs/`.
- Reproduce legacy bugs listed under "Intentional deltas" in a spec.
