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
- **Coordinates:** `MeetingLocation` as `Mapped(GeoPoint) | Unmapped`.
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

Decisions taken while implementing:
- **Malformed rows are skipped.** A row without a readable `id_bigint`,
  `weekday_tinyint` or `start_time` is left out rather than failing the whole
  list, so one bad record never blanks the page. A response that is neither a
  list nor `{}` is still a `DecodeFailure`.
- **Directions need coordinates.** "Directions" is offered only for a meeting
  with coordinates. `0,0` or unreadable values count as none, because the
  legacy URL would otherwise open `query=undefined,undefined`.
- **Coordinates are named `Mapped` / `Unmapped`.** `Located` stays free for
  the GPS fix type in slice 2.

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
- `formatRows()` returns `Outcome<List<FormatRow>, Failure>`; it runs
  `GetFormats&lang_enum=da` and `GetFormats&lang_enum=en` and concatenates
  the rows. The live Danish server returns `da` rows for the default query and
  `[]` for `lang_enum=dk`, so the legacy pair never yielded English names.

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
Features publish these through a small `BusyTracker.track(activity, work)`.
It lives in `na_kernel` next to the `EventBus`, because the nearby search and
events need it too and it is pure logic over the port. `track` always ends in
`finally`, so a failed request never leaves the bar stuck. The shell's
`LoadingActive` holds a `LoadingStatus` (literal text or a `BusyActivity`),
and the loading-bar widget turns the activity into ARB text at build time,
so the notifier needs no localisation.

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
- language → a new `tertiary` token
- audience → primary
- facility and content → a new `dark` token, `#222428`

Accessibility changes found by the `textContrastGuideline` checks (D10):
- White text on the legacy danger red `#F04141` measures 3.8:1, and less on
  small anti-aliased chip text. `danger` becomes `#B71C1C` (6.4:1 on white,
  5.7:1 on the `#eeeeee` surface), which also fixes slice 0's red error text.
- The legacy tertiary `#5260ff` fails at chip size. `tertiary` becomes
  `#3F4BD9` (6.5:1 on white).
- Chip text is 13 px instead of the legacy 11 px, and popover key badges use
  16 px text: at smaller sizes the anti-aliased strokes fail the measured
  contrast even where the colours pass.
- The range slider's track gesture is excluded from semantics; its two thumbs
  carry the slider semantics and actions.

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

The slice 0 checks found two accessibility problems, both fixed:
- The selected side-menu entry showed its 16 px label in the secondary blue
  (3.9:1 on the surface). The label is now primary blue (6:1); the selection
  is shown by the secondary-blue icon and a secondary-blue bar on the left
  edge. The secondary blue stays as it is, because today's section header
  (18 px, large text, 3:1 required) depends on it.
- The option dialog's "Cancel" button was 42 px tall; it now has a 48 × 48
  minimum.

Two helpers exist because of a limit of the text-contrast check:
`expectAccessible` runs all four guidelines, and `expectTapTargetsAccessible`
leaves out contrast. The second is used only where a dialog route sits over a
dimmed page and the check mis-places the text it samples. The same content
is checked for contrast on its own. `na_design` takes `na_testing` as a dev
dependency so its own tests share these helpers.

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
- `bus` in da becomes "Bus", `train` in da becomes "Tog".
- `findingMtgs` becomes "Finding meetings…" / "Finder møder …".
- The English values follow the spec's sentence case: `tempClosed`
  "Temporarily closed", `virtualLink` "Virtual link", `phoneMeeting` "Phone
  meeting dial-in", `meetingFormats` "Meeting formats", `nothingFound`
  "Nothing found", `weekdays` "All days". The Danish values are unchanged.

These keys are new:
- `municipalityOnline` ("Online")
- `meetingsLoadFailed`, `tryAgain`
- `hourRangeLower`, `hourRangeUpper` (the accessibility labels of the two
  hour-range thumbs, which the acceptance tests also drive)
- `meetingFormatsOpen` (the chip-row semantics label), `meetingDayFilter` ("Day", the day selector label)
- `meetingDayCount` ("{day} ({count})"), `meetingBadge` ("{day} {start} -
  {end}"), `meetingBusLines` ("Bus: {lines}"), `meetingTrainLines`
  ("Train: {lines}" / "Tog: {lines}")

The postal code is a plain location line and needs no label. The
`docs/LEGACY_PARITY.md` rows for these keys are corrected to the key
names actually used. They had listed planned names such as `pageMeetings`
that were never adopted.

## Risks / Trade-offs

- **Danish collation.** Dart has no ICU collation. `DanishCollation` follows
  ICU `da` for the letters BMLT format names use: a–z, then æ (and ä), ø (and
  ö), å (and "aa"), case-insensitive first, case as tie-break, common accents
  folded to their base letter. Table-driven tests cover the legacy Jest cases.
- **Imported legacy cache is Danish only.** The legacy app cached only `da`
  rows, so after the import an English UI shows Danish format names until
  the cache expires (at most 7 days). Accepted; the Danish UI is the default.
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
