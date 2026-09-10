# Architecture

Hexagonal Flutter app: pure domain in the middle, ports around it, adapters and
features outside, one composition root. Dependencies only point inwards.

## Layers

```
┌──────────────────────────────────────────────────────────────────────────┐
│ app/                       composition root: ProviderContainer, router,  │
│                            env config, native runners, acceptance + E2E  │
├───────────────────────────────┬──────────────────────────────────────────┤
│ packages/features/*           │ packages/adapters/*                      │
│ use cases (Notifiers) +       │ one package per external system:         │
│ widgets, one per capability   │ BMLT, WordPress, storage, audio, cast,   │
│                               │ geolocation, maps, notifications, clock, │
│                               │ legacy store                             │
├───────────────────────────────┴──────────────────────────────────────────┤
│ packages/core/na_ports        abstract interface class ports +           │
│                               throwing Riverpod providers                │
├──────────────────────────────────────────────────────────────────────────┤
│ packages/core/na_kernel       value types, sealed results, LocalDate,    │
│                               Clock/Ticker/Scheduler, EventBus, pure     │
│                               logic (catalog normalisation, clean time)  │
└──────────────────────────────────────────────────────────────────────────┘
   side packages: na_design (widgets layer UI kit), na_l10n (ARB), na_testing
```

## Packages and allowed imports

| Package | Responsibility | May import |
|---|---|---|
| `na_kernel` | Value types (`extension type const`), `Outcome`, `LoadResult`, domain sealed classes, `LocalDate`, time ports' pure parts, `EventBus`, pure algorithms | Dart SDK, `collection`, `meta` |
| `na_ports` | Port interfaces (`abstract interface class`) and one throwing provider per port | `na_kernel`, `flutter_riverpod` |
| `na_l10n` | `app_en.arb`, `app_da.arb`, generated `AppLocalizations` | Flutter |
| `na_design` | Tokens, primitives (`NaText`, `NaButton`, `NaCard`, `NaChip`, `NaSlider`, `NaListSection`, …), `flutter_bridge` for the few `StatefulWidget`s, `NaPage` | Flutter widgets layer, `na_kernel` |
| `feature_<capability>` | `Notifier`s (use cases) and widgets of one capability | `na_kernel`, `na_ports`, `na_design`, `na_l10n`, `flutter_riverpod` |
| `feature_meetings` (library) | Shared meeting list, card, formats popover; used by `feature_meetings_search`, `feature_meetings_map` | as features |
| `feature_media_player` (library) | Docked player and playback `Notifier`; used by `feature_audiobooks`, `feature_speaks` | as features |
| `adapter_<system>` | Implements ports for one external system; exports `List<Override> <system>Overrides({...})` | `na_kernel`, `na_ports`, the SDK/package it wraps |
| `na_testing` | Builders, mimics, `TestTime`, `TestContainer` | `na_kernel`, `na_ports`, `flutter_test` |
| `app` | `main.dart`, `ProviderContainer`, `GoRouter`, env, platform runners | everything above |

Rules enforced by `./bin/na check deps`:

- kernel ← ports ← features / adapters ← app. Never the other direction.
- Features never import adapters and never import other features, except the
  two libraries `feature_meetings` and `feature_media_player`.
- Adapters never import features, `na_design` or `na_l10n`.
- Nothing imports `app/`.
- `na_design` uses the widgets layer only; no Material or Cupertino anywhere.
- Nullable and boolean values from the outside stop in adapters,
  `na_kernel/lib/src/boundary/**`, `na_design/lib/src/flutter_bridge/**` and
  generated code.

## Riverpod wiring

- Every port has a provider in `na_ports` that throws `UnimplementedError`
  until overridden: `final clockProvider = Provider<Clock>((_) => throw ...)`.
- Every adapter exports `List<Override> xOverrides(...)`, e.g.
  `bmltOverrides(baseUrls: ...)`, `storageOverrides(prefs: ...)`.
- `app/lib/main.dart` builds one `ProviderContainer(overrides: [...all
  adapters...])` and mounts it with `UncontrolledProviderScope`. No global
  `ProviderScope`, no singletons, no static state.
- Features expose `NotifierProvider`s; widgets `ref.watch(x.select(...))` the
  narrowest slice.
- Tests build `TestContainer(overrides: [...mimics...])` from `na_testing`,
  which pre-wires `TestTime`, `KeyValueStoreMimic` and a recording `EventBus`.

## Types policy

- No nullable types, no `!`, no `bool` declarations, no `Option<T>`.
- `Outcome<T, F>` (`Ok` / `Err`) is the result of a use case; `F` is a sealed
  failure type of that use case.
- `LoadResult<T>` (`Loading` / `Loaded` / `Failed`) is UI state.
- Every other absence is a named sealed class: `MeetingVenue`, `ResumeState`,
  `CastSession`, `SpeakDate`.
- Ids, keys, URLs, distances, seconds: `extension type const`.
- Switches are exhaustive expressions; no `_`, no `default`.

## Events, time, streams

- `EventBus` (kernel) carries sealed `DomainEvent`s between features:
  `LanguageChanged`, `SettingsChanged`, `ResumePointSaved`,
  `LegacyMigrationCompleted`, `CastSessionChanged`.
- Time is injected: `Clock.now()` / `Clock.today()`, `Ticker.every(duration)`
  as a `Stream`, `Scheduler.after(duration, action)`. `adapter_clock` is the
  real one; `TestTime` in tests.
- Adapters expose `Stream`s (position, session state, location); features
  subscribe. No polling where a stream exists; where the SDK only offers
  polling (Cast position), the adapter polls and exposes a stream.

## Design system

`na_design` holds tokens (`NaColors`: background `#dddddd`, card `#eeeeee`,
primary `#0a61ad`, secondary `#0b77d3`, weekday colours; `NaSpacing`;
`NaTypography` on IBM Plex Sans), primitives built on `RenderObjectWidget`s
and `Text`/`GestureDetector`/`Semantics`, and `flutter_bridge` for stateful
pieces (slider drag, sheet, drawer, text field). Every widget has a golden and
passes `meetsGuideline` checks.

## Navigation

`GoRouter` with `WidgetsApp.router`; routes mirror the legacy paths (see
`docs/LEGACY_PARITY.md`). `NaPage` is a custom `Page` with the app's slide
transition and a `BackBehaviour` (closeModal, popToParent, goHome, background)
that the shell evaluates for the system back button. Modals (meeting details,
formats popover) are routes with `NaModalPage`.

## Configuration

`--dart-define-from-file env/<name>.json` with `APP_ENV`, `NA_API_BASE_URL`,
`BMLT_DENMARK_BASE_URL`, `BMLT_TOMATO_BASE_URL`, `NA_API_BASIC_AUTH`,
`GOOGLE_MAPS_API_KEY` (and `NA_APPROVED`). `env/dev.json` and `env/test.json`
are committed; `env/release.json` is created by CI from secrets and never
committed. `AppConfig` in `app/` parses them once into typed values.

## Legacy migration plugin

`adapter_legacy_store` wraps a small native plugin that opens the Ionic
WebView's IndexedDB (`_ionicstorage` / `_ionickv`, origin `https://localhost`
on Android, `ionic://localhost` on iOS) read-only and returns all pairs as
JSON. The pure translation to typed settings lives in
`na_kernel/lib/src/boundary/legacy_migration.dart`; the use case in
`feature_legacy_migration` runs once before first render. Contract:
`openspec/specs/legacy-migration/spec.md`.
