# Design

## Context

Slice 0 set the patterns this slice follows:
- kernel value types with `Outcome` / `LoadResult`
- ports created by `unboundPort`
- port-level mimics in `na_testing` for feature tests
- `TestContainer` with `TestTime`
- `pumpFeature` for widget tests
- `pumpApp` for acceptance tests
- features composed by the router in `app/`

Constraints that shape this design:
- **No shared loading bar yet.** `GlobalLoading` lives in `feature_shell`, and
  no other feature can use it: `LayerRules` forbids feature → feature imports,
  except into `feature_meetings` and `feature_media_player`.
- **Settings stay in `feature_settings`.** The current language and first day
  of week live there, and `feature_meetings` may not import it.
- **The Denmark list is small enough to fetch whole.** It returns a few hundred
  meetings.
- **Other slices reuse the formats index and the meeting list.** Slice 2
  (nearby) and slice 7 (map) need them unchanged.

See `proposal.md` for scope. `specs/` holds the behaviour.

## Goals / Non-Goals

**Goals:**
- Keep all meeting and format rules pure and in the kernel, so later slices
  reuse them.
- Test every wire interaction against a mimic that speaks real BMLT JSON.
- Have every design-system component covered by a golden and an
  accessibility check.

**Non-Goals:**
- Caching the meeting list itself. Every visit to a municipality fetches.
- Offline mode for meetings.
- The details modal, meetings by id, and Tomato radius queries. These are
  slices 2 and 7.

## Decisions

### D1 Packages

`feature_meetings` is the library:
- the formats controller
- the meeting-list state
- the meeting list, card, chips and formats popover widgets

`feature_meetings_search` holds the `/listfull` pages. The nearby page joins it
in slice 2.

`adapter_bmlt` implements the ports.

This follows `docs/ARCHITECTURE.md` and the `LayerRules` bridge list.
Alternative: `feature_listfull` per page (the original plan). It was rejected
because the repo docs and the checker already use the capability-named
package.

### D2 Kernel domain

All of these are pure types in `na_kernel/lib/src/meetings/`:
- **Meeting data:** `Meeting`, `MeetingId`, `MunicipalityName`.
- **Venue:** `MeetingVenue` as `InPerson | Virtual(link) | Hybrid(link)`.
- **Coordinates:** `MeetingLocation` as `Located(GeoPoint) | Unlocated`.
- **Contact fields:** `DialIn`, `MeetingComment` and the list of present
  `LocationLine`s.

The rules live on the types:
- `TemporaryClosure` and hybrid use whole-key matching.
- `schedule`: start `LocalTime` plus `duration`, giving the end time.
- `actions`: directions, virtual link, dial-in.
- `Municipality.normalise`: the "Online" grouping.
- `TransitLine`: prefix stripping.

These are wire-agnostic, which keeps them cheap to unit test and lets slices 2
and 7 reuse them unchanged. Nullable and blank BMLT fields stop in
`na_kernel/lib/src/boundary/bmlt_meeting_reader.dart`. That reader turns a JSON
map into a `Meeting` through `JsonReader`, trimming values and mapping a blank
value to the "absent" case of the matching sealed type.

### D3 Formats

These are pure kernel types:
- **Raw data:** `FormatRow`, the raw GetFormats row, with its own boundary
  reader and writer so the cache stores exactly what the server sent.
- **Index:** `FormatIndex.build(rows, displayLanguage)` holds by-id, by-key,
  by-lower-key (ambiguous entries removed permanently) and English-key maps.
- **Resolution:** `FormatResolver.resolve(meeting, index)`.
- **Classification and ordering:** `FormatCategory`, and `DanishCollation` for
  name ordering.

`MeetingFormatsController` in `feature_meetings` owns the cache policy:
- It reads the cache from `KeyValueStorePort` (`meetingFormatsCache`) and uses
  `Clock` for the 7-day and 60 s windows.
- It keeps one in-flight `Future` so concurrent requests share a fetch.
- It exposes `LoadResult<List<FormatRow>>`.

A provider family keyed by `Language` derives the `FormatIndex`, so a language
change rebuilds the index without a refetch.

Alternative: cache inside `adapter_bmlt`. It was rejected because the cache
policy is behaviour the spec tests, and features must be testable without
adapters.

### D4 Ports

`MeetingSearchPort`:
- `denmarkMeetings()` returns `Outcome<List<Meeting>, Failure>`
- `denmarkMunicipalities()` returns `Outcome<List<MunicipalityName>, Failure>`

`MeetingFormatsPort`:
- `formatRows()` returns `Outcome<List<FormatRow>, Failure>`; it runs both
  GetFormats queries concatenated.

The Tomato methods arrive in slice 2. Keeping the ports this small keeps each
slice's mimics honest.

### D5 BMLT adapter and mimic

`adapter_bmlt` uses `dio` with the base URLs from `BmltEndpoints` (typed
`BaseUrl` values). `app/` parses `BMLT_DENMARK_BASE_URL` and
`BMLT_TOMATO_BASE_URL` with `String.fromEnvironment` once in a new
`AppConfig`.

The adapter builds the exact query strings from the spec, so `meeting_ids[]`
and `sort_keys` are never re-encoded. It maps `{}` to an empty list,
`DioException` to `NetworkFailure`, and bad JSON to `DecodeFailure`.

`BmltServerMimic` in `na_testing` is a `dio` `HttpClientAdapter`:
- It serves JSON built by `aBmltMeetingJson(...)` / `aBmltFormatJson(...)` per
  switcher.
- It records every request URI.
- It can fail, hang (a `Completer` released by the test) or answer `{}`.

Alternative: an in-process `HttpServer`. It was rejected because real sockets
inside `testWidgets` need `runAsync` and slow every acceptance test.

Recorded fixtures under `na_testing/fixtures/wire/bmlt/` seed the builders'
defaults. They are one real meeting row and one format row from each language.

### D6 Loading bar across features

This adds a `BusyActivity` enum (`findingMeetings`, and later `locating` and
`loadingEvents`) and two domain events, `BusyStarted(activity)` and
`BusyEnded(activity)`.

`feature_shell` subscribes on the `EventBus`. It maps each event to
`GlobalLoading.present(text)` / `dismiss()`, taking the text from the ARB.
Features publish these through a small `BusyTracker.track(activity, future)`
in `feature_meetings`. `track` always ends in `finally`, so a failed request
never leaves the bar stuck.

Alternative: move `GlobalLoading` into `na_ports`. It was rejected because the
architecture routes cross-feature signals through the `EventBus`, and the text
belongs to the shell's localisation.

### D7 Page state and navigation

- **Routes.** `/listfull` and `/listfull/:municipality` are both `GoRoute`s in
  the app router.
- **Back.** The sub-page is a `ShellPage` with
  `BackTo(parent: MenuDestination.meetings.path)`, and `BackRule` returns
  `PopToParent` for any path under `/listfull/`.
- **Menu.** The side menu treats a destination as selected when the location
  equals its path or starts with its path followed by `/`.
- **Loading state.** `MunicipalitiesController` (`autoDispose`) and
  `MunicipalityMeetingsController` (`autoDispose` family keyed by
  `MunicipalityName`) start loading in `build` and expose `LoadResult`.
  Leaving the sub-page disposes the state. Revisiting starts in `Loading`,
  which is why a previous municipality is never shown.
- **Composition.** Features never navigate. The app passes
  `onOpen: (name) => context.go(...)` and the current `FirstDayOfWeek` from
  `currentSettingsProvider` into the page bodies, as it already does for
  `JftPreviewCard`.
- **Format language.** Widgets take it from `Localizations.localeOf(context)`.

### D8 Meeting list state

`MeetingListController` is an `autoDispose` family keyed by a
`MeetingListKey`, the municipality for now. It holds:
- `DayFilter`: `AllDays | OnlyDay(weekday)`
- `HourRange` (0–23)
- `OpenSection`: `NoSectionOpen | SectionOpen(weekday)`. This is keyed by
  weekday, not by index, so filtering never opens another day.

The hour range is applied through `Scheduler.debounce(350 ms)`. Grouping,
counting and filtering are the pure kernel functions `MeetingSchedule.group`
and `MeetingFilter.apply`, starting from the unfiltered list each time.

"Today" comes from `Clock.today().weekday`, never the device clock.

### D9 Design system additions

These go in `na_design`:
- `NaSectionHeader`: a tappable header with a count, a highlight variant and
  an expand icon.
- `NaChip`: with `NaChipTone` of danger, language, primary or dark.
- `NaBadge`
- `NaNote`: the comments callout.
- `NaPopover`: shown with `showNaPopover` on `showGeneralDialog`, like
  `NaOptionDialog`, so system back pops it first.
- `NaRangeSlider`: in `flutter_bridge`, with two thumbs, drag and
  `Semantics` increase/decrease per thumb.
- `NaDisclosureRow`: a municipality row with a chevron.
- Icons: `play`, `note`, `phone`, `cloud`, `mapPin`, `clock`, `add`, `close`.

Chip tones map to the legacy colours:
- alert → danger
- language → a new `tertiary` token, `#5260ff` (the legacy
  `--ion-color-tertiary`)
- audience → primary
- facility and content → a new `dark` token, `#222428`

### D10 Goldens and accessibility

`na_testing` gains:
- `loadNaFonts()`: registers the bundled Plex font from the repo through
  `RepoAssetBundle`, so goldens render real glyphs.
- `expectGolden(finder, name)`: wraps `matchesGoldenFile` under
  `test/widget/goldens/`.
- `expectAccessible(tester)`: runs `androidTapTargetGuideline`,
  `iOSTapTargetGuideline`, `labeledTapTargetGuideline` and
  `textContrastGuideline`.

Goldens run only on Linux, the CI image, and are skipped elsewhere by test
config. They are regenerated with `./bin/na test widget --update-goldens`.

Slice 0 components and pages (settings, contact, JFT, home, shell) get the
same treatment in a separate task group, so any regression they reveal stays
visible on its own.

### D11 Legacy import

`LegacyMeetingFormatsTranslation` in the kernel boundary:
- validates `fetchedAt` (a number) and a non-empty `formats` array
- re-encodes the value as JSON under `meetingFormatsCache`

The existing import use case adds this key to its imported and skipped counts
and never overwrites an existing value.

### D12 Localisation

The existing legacy-mapped ARB keys stay: `listfull`, `findingMtgs`,
`tempClosed`, `map`, `virtualLink`, `phoneMeeting`, `bus`, `train`, `weekdays`,
`back`, `nothingFound`, `meetingFormats`, `close`, and the weekday names.

These values change:
- `bus` in da becomes "Bus"
- `train` in da becomes "Tog"
- `weekdays` in en becomes "All days"

These keys are new:
- `municipalityOnline` ("Online")
- `meetingsLoadFailed`
- `tryAgain`
- `hourRangeLabel` (accessibility)
- `meetingFormatsOpen` (the chip-row semantics label)

The postal code is a plain location line and needs no label. The
`docs/LEGACY_PARITY.md` rows for these keys are corrected to the key
names actually used. They had listed planned names such as `pageMeetings`
that were never adopted.

## Risks / Trade-offs

- **Danish collation.** Dart has no ICU collation. `DanishCollation` orders
  a–z, æ, ø, å, case-insensitively, and treats "aa" as plain letters, which
  matches `localeCompare('da')` for BMLT format names. Table-driven tests
  cover the legacy Jest cases.
- **Popover and system back.** `showGeneralDialog` uses the root navigator
  above the `ShellRoute`. If GoRouter handles the back press before the
  dialog, the acceptance scenario "Back closes the formats popover first"
  fails. The fallback is a `PopScope` inside `NaPopover`.
- **Goldens across machines.** Anti-aliasing can differ between developer
  machines and CI. Goldens are generated on Linux with the bundled font and
  checked only on Linux. A mismatch prints the failure images for review.
- **Patrol and screenshots.** They need an emulator, and iOS needs macOS.
  - The Android Patrol happy path and screenshots are tasks.
  - iOS screenshots join slice 0's open macOS task.
- **Postal code field name.** The spec now names `location_postal_code_1`
  (the BMLT field). If the Danish server leaves it empty for every meeting,
  the line simply never shows. This is harmless.

## Migration Plan

- No data migration beyond D11.
- The first start after this change reads `meetingFormatsCache`, which is
  empty unless the legacy import filled it, and fetches once.
- To roll back, revert the PR. The only new stored key is
  `meetingFormatsCache`, which older builds ignore.

## Open Questions

- The Danish error texts ("Møderne kunne ikke hentes", "Prøv igen") are
  proposed wording. The NA Danmark team may prefer other phrasing. Changing
  the ARB values later does not change any behaviour.
