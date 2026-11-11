# Design

## Context

Earlier slices provide:
- `MediaPlayer`, `ResumePoints` (with the `speaks` index), `ProgressTexts`,
  `ProgressLine` and the docked player, all of which already handle
  `PlaylistKind.speak` (slice 4);
- the speak resume-point migration (slice 4);
- `Scheduler.debounce` with `TestTime` fakes, `WireJson`, `LenientText`;
- `adapter_bmlt` as the pattern for a `dio` adapter tested against an
  `HttpClientAdapter` mimic;
- every speak text in both ARB files (`speak*`, `openingSpeaker`,
  `mainSpeaker`, `closingSpeaker`, `languageDanish`, `languageEnglish`,
  `playerContinueListening`, `close`);
- `NA_API_BASE_URL` and `NA_API_BASIC_AUTH` in `env/*.json` and the release
  secrets.

What is missing:
- The feed DTOs, the catalogue rules, the port and the adapter.
- A text field, toggle chips, swipe actions and pull-to-refresh in the design
  system. The app has no Material widgets, so each is built on the widgets
  layer.

Constraints:
- The feed needs the Basic-auth secret; the endpoint answers 401 without it.
  No real response can be recorded on a machine without the secret, so the
  fixtures are a synthetic sample built from the messy cases the legacy code
  documents.
- `LayerRules`: features import only the bridge features. `feature_speaks`
  depends on `feature_media_player`, never on another page feature.

## Goals / Non-Goals

**Goals:**
- Every normalisation rule is a pure kernel function with table tests taken
  from the spec and the legacy comments.
- Filtering, sorting, grouping, paging and the continue list are one pure
  function of (catalogue, filters, resume state), unit-tested without widgets.
- Rows rebuild only when their own playback or resume state changes, not on
  every position tick of another speak.

**Non-Goals:**
- Recording the real feed. A follow-up can replace the sample with a
  recording once the secret is available on a development machine.

## Decisions

### D1 Packages

- `na_kernel/lib/src/speaks/`: `FeedText` (fold/tidy), values, `Speak`,
  `SpeakConvention`, `SpeakDate`, `SpeakCatalog` with its builder; the DTOs
  and `SpeaksMapper` in `lib/src/boundary/speaks_wire.dart`.
- `na_ports`: `SpeaksFeedPort` and `speaksFeedPortProvider`.
- `adapter_wordpress` (new): `WordPressEndpoints`, `DioSpeaksFeed`,
  `wordpressOverrides(...)`. Events (slice 6) use the same package.
- `feature_speaks` (new): `SpeaksCatalogLoader`, `SpeakFiltersController`,
  `SpeakListing`, `SpeakResumes`, `SpeakTexts`, `SpeaksBody` and its parts.
- `na_design`: the widgets of D9.
- `na_testing`: D10.

### D2 Feed, DTOs and mapper

`GET <base>/wp-json/wp/v2/speaks?excerpt[]=NA-SPEAKS-DK` (and `-EN`) with
`Authorization: Basic base64(<NA_API_BASIC_AUTH>)`. When the define is empty
the header is left out (`NoCredentials`) and the server's 401 shows the error
state. `excerpt[]` is written literally, as the legacy app did.

`SpeakGroupDto {title, speaks}` and `SpeakEntryDto {name, location, year,
audioUrl}` are lenient (`LenientText` on every scalar, so a numeric `year`
reads as text). `SpeaksMapper.groups(json:, language:)` reads the array with
`WireJson.rows` (a group that does not decode is dropped; `{}` is an empty
feed; anything else is a `DecodeFailure`) and maps each group to
`FeedGroup {title, language, entries}`. An entry whose trimmed `audioUrl` is
empty or not an absolute `http(s)` URI is dropped there, so the domain only
sees `FeedEntry {id: PlaylistId, url: AudioUrl, name, location, year}`.

```dart
abstract interface class SpeaksFeedPort {
  Future<Outcome<List<FeedGroup>, Failure>> feed({required SpeakLanguage language});
}
```

### D3 Kernel values

- `SpeakLanguage { danish('da', 'NA-SPEAKS-DK'), english('en', 'NA-SPEAKS-EN') }`.
- `FeedText(String)` with `tidied`, `folded` (a `FoldedText`) and
  `isBlank`. Folding replaces `æ`/`ø`/`å`, then decomposes with
  `unorm_dart`'s NFD and drops U+0300–U+036F; no hand-written decomposition.
- `SpeakKind { opening, main, closing }`; `DetectedKind` sealed: `KindOf` /
  `NoKind`. `Speaker` sealed: `NamedSpeaker(SpeakerName)` / `NoSpeaker`.
- `ConventionKey`, `ConventionLabel`, `CityName`; `ConventionCity` sealed:
  `InCity` / `NoCity`.
- `SpeakDate` sealed: `FullDate(LocalDate)`, `YearOnly(SpeakYear)`,
  `UnknownDate`; `sortKey` (`SpeakSortKey`, 0 for unknown) and `timeLabel`.
- `SpeakEdition` sealed: `EditionOf(EditionText)` / `NoEdition`.
- `SpeakTitle` sealed: `SpeakerTitle`, `KindTitle`, `EditionTitle`,
  `ConventionTitle`. Only `KindTitle` needs localisation.
- `MetaPart(String)`; `Speak.meta` and `Speak.context` are lists of parts
  (zero to three), so no empty-text placeholder exists.
- `SearchText`; `Speak.matches(terms)` is the AND substring rule.

### D4 Catalogue builder

`SpeakCatalog.build({groups, kindWords})` follows `buildSpeakCatalog` step by
step. `kindWords` (`SpeakKindWords`) holds the folded kind labels of both
languages; the feature reads them from `lookupAppLocalizations` for `da` and
`en`, so the kernel stays free of display text while search still finds
"hovedspeak" and "main speak" in either app language. The language search
words (`english engelsk udenlandske`, `dansk danish`) are search keys from the
spec and live in the kernel.

The catalogue's conventions keep first-seen order; a convention's city is the
first city seen. Years are distinct and newest first.

### D5 Catalogue loader

`speaksCatalogProvider` is a kept-alive `NotifierProvider<SpeaksCatalogLoader,
CatalogState>`:
- `CatalogLoading()` → `CatalogReady(catalog, refresh)` or
  `CatalogFailed(failure)`;
- `reload()` from `CatalogReady` sets `refresh: RefreshState.refreshing` and
  keeps the catalogue on failure; from `CatalogFailed` it goes back to
  `CatalogLoading`.

Both feeds are fetched in parallel; an `Err` contributes no groups; two
`Err`s fail the load with the Danish feed's failure.

### D6 Filters, listing and continue list

`speakFiltersProvider` (auto-dispose, so leaving the page resets it) holds
`SpeakFilters {typed, selection, panel, shown}` where `selection` is
`SpeakSelection {query, languages, conventions, years, onlyStarted, sort}`.
Typing updates `typed` at once and `selection.query` through a 200 ms
debouncer from `Scheduler`. Every selection change resets `shown` to 40.
`showMore(after:)` adds 40 only when `shown` still equals `after`, so a burst
of scroll notifications loads one page.

`SpeakResumes.of({catalog, library, active})` gives the continue list (≤ 10,
active first, then `updatedAt` descending, only points with a
`TrackProgress` other than `NoProgress`) and the started set (those plus the
active speak).

`SpeakListing.of({catalog, selection, shown, started, titles})` returns the
match count, the visible sections, `MoreSpeaks`, the year options, the
active filter count and `FiltersInUse`. Selected conventions missing from a
reloaded catalogue are ignored. `titles` renders `KindTitle`s for the Name
sort, so `speakListingProvider` is a family over `Language`, which the page
reads from its locale.

The scroll view is keyed by the selection, so any selection change starts a
new scroll position at the top.

### D7 Sorting without a collation library

Dart has no locale collation, and the earlier decision is not to hand-roll
one. Name sort and tie-breaks compare the folded titles (the spec's own fold
rule), then the raw titles. Danish names starting with `Æ`, `Ø` or `Å` sort
with `Ae`, `O` and `A` instead of after `Z`; the feed's speaker names are
mostly ASCII, so the difference is small. This is listed as an intentional
delta.

### D8 Rows and playback

`speakPlaybackProvider` is not needed: a row watches
`mediaPlayerProvider.select((p) => SpeakPlayback.of(id, p))`, which is
`NotPlayingSpeak()` or `PlayingSpeak(status, position, length)` with value
equality, and `resumePointsProvider.select(...)` for its own `ResumeState`.
`SpeakRowView.of(...)` gives the icon (play, pause, loading), the
`TrackProgress` and the tone (started or plain).

Tapping plays `MediaPlaylist {id: url, kind: speak, title: group title,
cover: BundledCover(na-logo), tracks: [one track, label '']}` with
`ContinueListening`; the player toggles when the speak is already active.
The track title is `<title>[ · <kind label>][ · <meta>]`, rendered with the
app language.

### D9 Design system

Bridge widgets (stateful, in `flutter_bridge`):
- `NaSearchField`: `EditableText` with a search icon, placeholder and clear
  button; controlled by its `text`, it updates its controller only when the
  given text differs (reset clears it).
- `NaSwipeActions`: a horizontal drag reveals one action button at the end;
  release past half opens it, a tap on the content closes it. Semantics
  expose the action as a custom action so screen readers reach it without
  swiping.
- `NaPullToRefresh`: wraps a scroll view with always-scrollable bouncing
  physics; an overscroll of 80 px released at the top calls `onRefresh`. While
  `activity` is busy it shows a spinner above the list.

Primitives: `NaToggleChip` (filled when selected, outlined otherwise,
semantics `selected`), `NaChipStrip` (horizontal scroll), `NaMessageBlock`
(title, body, optional button), `NaSkeletonRow`, `NaToolbarButton` (icon
plus label), `NaIcons.funnel`.

### D10 Tests

- Kernel: table tests for every text, convention, date, kind, title and meta
  scenario; catalogue tests for dedupe, counts, cities, years, search text.
- Adapter: `DioSpeaksFeed` against `WordPressMimic` (paths, the literal
  `excerpt[]`, Basic auth, 401, 500, unreachable, malformed, `{}`).
- Feature: loader, filters (debounce on `TestTime`), listing, continue list
  and row views as unit tests; widget tests and goldens for the loaded,
  loading, error, empty, filter-panel and continue states with
  `expectAccessible`.
- Acceptance: one test per speaks scenario through the app with
  `WordPressMimic` behind the real adapter.
- Patrol: open Speaks, play the first speak, see the docked player, pause and
  close it, with `WordPressMimic` as the network.

## Risks / Trade-offs

- The sample feed may miss shapes the real feed has. The mapper is lenient
  and drops bad groups and entries instead of failing the page.
- A catalogue of about a thousand speaks is filtered on every keystroke after
  the debounce; the work is linear and runs off position ticks, which only
  rebuild the active row.
- Pull-to-refresh is hand-made on the widgets layer because the Material
  `RefreshIndicator` is banned.

## Migration Plan

None. Speak resume points were migrated in slice 4 and keep their keys.
