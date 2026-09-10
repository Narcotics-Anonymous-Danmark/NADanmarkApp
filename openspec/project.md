# NA Danmark App

## Purpose

The mobile app of Narcotics Anonymous Danmark for iOS and Android. It finds NA
meetings (list, nearby, map), shows the daily "Just for Today" reading, counts
clean time, lists recovery events, plays the Danish audiobooks and recorded
speaks, and shows the group readings. This repository is a Flutter rewrite of the
Ionic/Cordova app in the sibling repository `../App`. The legacy app defines the
behaviour to reach; the specs in `openspec/specs/` are the contract the rewrite
is tested against. Both apps ship under the same store ids: `dk.nadanmark.app`
(Android) and `dk.nadanmark.ios.app` (iOS).

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.41 / Dart 3.11, widgets layer only (no Material, no Cupertino) |
| State | Riverpod 3 with an explicit `ProviderContainer`; `Notifier`s per feature |
| Architecture | Hexagonal: `na_kernel` ← `na_ports` ← `packages/features/*`, `packages/adapters/*` ← `app/` |
| Navigation | go_router behind `WidgetsApp.router`, custom `NaPage` transitions |
| Localisation | ARB files in `packages/core/na_l10n` (`app_da.arb`, `app_en.arb`), Danish default |
| Design system | `packages/core/na_design`: tokens, primitives, `flutter_bridge` for the few stateful widgets |
| Audio | `just_audio` + `audio_service`, Chromecast and AirPlay through a small native plugin |
| Maps | Google Maps SDK through `google_maps_flutter`, Places autocomplete over HTTPS |
| Storage | `shared_preferences` behind a `KeyValueStore` port; one-time import of Ionic Storage |
| Tests | `flutter_test` (unit, widget, acceptance), Patrol (E2E), goldens, `meetsGuideline` a11y |
| Tooling | Flutter pinned in `.fvmrc` (fvm locally, subosito/flutter-action in CI), JDK 17 and Android SDK from the host; `./bin/na` is the only entry point |
| CI | GitHub Actions; emulator + simulator per PR, real devices nightly on Firebase Test Lab |
| Config | `--dart-define-from-file env/<name>.json`; `env/release.json` is never committed |

## Conventions

- Coding rules: `docs/CODING_GUIDELINES.md`. Every rule names the lint that enforces it; `./bin/na check` runs them all.
- Test strategy and naming: `docs/TESTING.md`. Every `#### Scenario:` in a spec is an acceptance test with the same name.
- Layering and Riverpod wiring: `docs/ARCHITECTURE.md`.
- Releases: `docs/RELEASING.md`. Version numbers change only through `./bin/na release version`.
- Legacy mapping (routes, storage keys, i18n keys, plugins): `docs/LEGACY_PARITY.md`.
- Specs use English UI strings. Where a Danish legacy string helps, it appears once in parentheses.
- Each spec ends with "Intentional deltas from the legacy app". Legacy bugs listed there are not reproduced.
- Changes are proposed with `/opsx:propose`, implemented with `/opsx:apply` and folded into `openspec/specs/` with `/opsx:archive`.

## Domain glossary

| Term | Meaning |
|---|---|
| BMLT | Basic Meeting List Toolbox, the NA meeting database. The app reads two root servers: the Danish root `https://www.nadanmark.dk/main_server/client_interface/json/` and the aggregator `https://tomato.bmltenabled.org/main_server/client_interface/json/`. |
| Meeting | One BMLT search result: `id_bigint`, `meeting_name`, `weekday_tinyint` (1 = Sunday … 7 = Saturday), `start_time` (`HH:mm:ss`), `duration_time`, `formats` (comma separated keys), `format_shared_id_list`, location fields, `latitude`/`longitude`, `virtual_meeting_link`, `phone_meeting_number`. |
| Meeting format | A BMLT format definition (`key_string`, `name_string`, `description_string`, `format_type_enum`, `lang`), categorised as alert, language, audience, facility or content. `TC` marks a temporarily closed meeting, `HY` a hybrid meeting. |
| Municipality | `location_municipality`; the grouping used by the full meeting list. Blank municipalities are shown as "Online". |
| Radius search | A BMLT `GetSearchResults` query with `geo_width_km`, `lat_val`, `long_val`; used by "Meetings nearby" and by the map. |
| Auto radius | On the map, the search radius derived from the visible region: distance from centre to the far-left corner in km × 1.1. |
| Clean date | The first clean day of a cleantime profile. |
| Cleantime profile | A named clean date (`name`, `cleandate`). A user may keep several; one is active. |
| Anniversary (cleanday, "Mærkedag") | A clean-time milestone: 1 day, 30, 60, 90 days, 6, 9, 18 months, 1 year, and every whole year after. |
| Keytag | The coloured NA key tag image shown on an anniversary; one image per anniversary and language. |
| JFT | "Just for Today" (Danish "Bare for i dag"), the daily meditation. 366 entries bundled with the app. |
| Event | A recovery event ("bedringsarrangement") from the nadanmark.dk WordPress calendar. |
| Audiobook | One of three Danish NA books read aloud: Basic Text (97 chapters), It Works: How and Why (39), Step Working Guides (13). |
| Speak | A recorded talk from an NA convention or meeting, served by the nadanmark.dk WordPress `speaks` feed in a Danish and an English list. |
| Convention | The grouping of speaks by event, e.g. "KOKNA", parsed from the feed group title. |
| Playlist | What the media player plays: a book (chapter queue, auto-advance) or a single speak. |
| Resume point | The saved listening position of a playlist: `trackId`, `trackIndex`, `position` seconds, optional `duration`, `updatedAt`. One per book, one per speak file. |
| Group readings (GRC) | The seven Danish readings read at the start of meetings. |
| Legacy store | The Ionic Storage IndexedDB database `_ionicstorage`, object store `_ionickv`, that the previous app wrote to. Imported once on first start. |
