# Tasks

## 1. Kernel domain (D2, D3)

- [ ] 1.1 Add `MeetingId`, `MunicipalityName`, `GeoPoint`, `MeetingVenue`, `MeetingLocation`, `DialIn`, `MeetingComment`, `LocationLine`, `TransitLine` and `Meeting` under `na_kernel/lib/src/meetings/`; verify with value-semantics unit tests
- [ ] 1.2 Add the meeting rules: whole-key TC/HY, the end time from start + duration (blank duration = start), directions / virtual / dial-in actions, and transit prefix stripping (case-insensitive, every occurrence); verify with unit tests covering every spec scenario of "Meeting card", "Meeting card actions", "Temporarily closed rule" and "Meeting times"
- [ ] 1.3 Add `Municipality.normalise` and the ordering (unique, server order, "Online" last), plus the online-group membership test; verify with unit tests for the three municipality scenarios
- [ ] 1.4 Add `MeetingSchedule.group` (first-day order, counts, start-time sort, stable ties) and `MeetingFilter` (`DayFilter`, `HourRange` on start hour, counts recomputed); verify with unit tests, including an hour range of 18–20 that excludes 17:30 and includes 20:59
- [ ] 1.5 Add `FormatRow`, `FormatCategory`, `FormatIndex.build` (display row dk/en/first, by-id, by-key, ambiguous lower-key removal including a third clashing row, English-key index) and `FormatResolver`; verify with table-driven unit tests ported from the legacy `meeting-formats.service.test.ts` cases
- [ ] 1.6 Add `DanishCollation`; verify with unit tests ordering a–z, æ, ø, å case-insensitively
- [ ] 1.7 Add boundary readers `BmltMeetingReader`, `FormatRowReader`/writer and `LegacyMeetingFormatsTranslation` in `na_kernel/lib/src/boundary/`, with trimming and blank = absent; verify with unit tests on the recorded fixture rows and malformed input
- [ ] 1.8 Add `BusyActivity`, `BusyStarted` and `BusyEnded` domain events; verify with a unit test publishing through `BroadcastEventBus`

## 2. Ports, builders and mimics (D4, D5)

- [ ] 2.1 Add `MeetingSearchPort` and `MeetingFormatsPort` with unbound providers; verify the unbound-port unit test lists both
- [ ] 2.2 Record one Danish meeting row, one municipality row and one format row per language into `na_testing/fixtures/wire/bmlt/`; add `aMeeting`, `aMeetingFormatRow`, `aBmltMeetingJson` and `aBmltFormatJson` builders seeded from them; verify with a builder unit test that decodes each through the boundary readers
- [ ] 2.3 Add `BmltServerMimic` (a dio `HttpClientAdapter`: per-switcher JSON, `{}`, failure, held responses, recorded URIs) plus `MeetingSearchMimic` and `MeetingFormatsMimic` port mimics, and wire the port mimics into `TestContainer`; verify with mimic unit tests
- [ ] 2.4 Add `dio` to `na_testing`; verify that `./bin/na check deps` passes

## 3. Acceptance tests first (red)

- [ ] 3.1 Extend `pumpApp` with a `BmltServerMimic`-backed `adapter_bmlt` override and `inPopover` finders; verify the harness compiles and the existing acceptance suite still passes
- [ ] 3.2 Write one `testWidgets` per scenario of the delta and main `meetings-search` requirements in scope: "BMLT endpoints" (the Denmark rows and the `{}` case), "Full meeting list by municipality", "Weekday grouping and ordering", "Day and hour filters", "Meeting times", "Meeting card", "Temporarily closed rule", "Meeting card actions", "Format definitions and cache", "Format category and display language", "Resolving a meeting's formats", "Formats popover" and "Loading states" (the "Finding meetings…" part). Place them in `app/test_acceptance/meetings_search/`, grouped by requirement; verify they fail for the missing feature, not for harness errors
- [ ] 3.3 Write the new `app-shell` scenarios ("Municipality sub-page keeps the menu entry", "Back from municipality meetings returns to the list", "Back closes the formats popover first") and the new `legacy-migration` scenarios ("Meeting formats cache is copied", "Empty meeting formats cache is dropped"); verify they fail for the missing feature

## 4. Use cases (feature_meetings, feature_meetings_search) (D3, D6, D7, D8)

- [ ] 4.1 Create `packages/features/feature_meetings` (library) and `packages/features/feature_meetings_search` and add them to the workspace and `coverage.yaml`; verify with `./bin/na check deps`
- [ ] 4.2 Implement `BusyTracker` and the shell side (`BusyStarted`/`BusyEnded` → `GlobalLoading`, ARB text per activity); verify with unit tests, including that a failed future still ends the activity
- [ ] 4.3 Implement `MeetingFormatsController` (7-day cache in `meetingFormatsCache`, stale fallback, 60 s retry, shared in-flight fetch, never writes empty) and the `formatIndexProvider(Language)` family; verify with unit tests driven by `TestTime`
- [ ] 4.4 Implement `MunicipalitiesController` and `MunicipalityMeetingsController` (`autoDispose`, `LoadResult`, retry, busy tracking); verify with unit tests for loaded, empty, failure, retry and no-stale-data
- [ ] 4.5 Implement `MeetingListController` (day filter, hour range through `Scheduler.debounce(350 ms)`, one open section keyed by weekday, today from `Clock`); verify with unit tests
- [ ] 4.6 Extend `feature_legacy_migration` with the formats-cache key (never overwrite, count imported/skipped); verify with unit tests

## 5. Design system (D9)

- [ ] 5.1 Add the `tertiary` (`#5260ff`) and `dark` (`#222428`) colour tokens and the new icons; verify the tokens unit test
- [ ] 5.2 Add `NaSectionHeader`, `NaChip` (+ `NaChipTone`), `NaBadge`, `NaNote` and `NaDisclosureRow`; verify with widget tests
- [ ] 5.3 Add `NaPopover` + `showNaPopover`; verify with a widget test that it closes on the close button, on the barrier and on system back
- [ ] 5.4 Add `NaRangeSlider` in `flutter_bridge` (two thumbs, step 1, drag, per-thumb semantics increase/decrease); verify with widget tests for drag, tap and semantics actions

## 6. Widgets (D7, D8)

- [ ] 6.1 Build `MeetingCard` (badge, TC chip, name, format chips, present lines, note, contact, transit, action buttons) and `FormatChips`; verify with widget tests for in-person, hybrid, virtual + phone and closed meetings
- [ ] 6.2 Build `FormatsPopoverBody` (meeting name, badge key, name, optional description); verify with a widget test
- [ ] 6.3 Build `MeetingList` (filter bar, sections, empty "Nothing found"); verify with widget tests for grouping, filtering and one-open-section
- [ ] 6.4 Build `MunicipalityListBody` and `MunicipalityMeetingsBody` with loading, empty and error + "Try again" states; verify with widget tests
- [ ] 6.5 Add the ARB keys and value changes from D12 to both files, regenerate with `./bin/na gen l10n`, and align `docs/LEGACY_PARITY.md`; verify with `./bin/na check arb`

## 7. Adapter and app wiring (D5, D7)

- [ ] 7.1 Create `packages/adapters/adapter_bmlt` (`DioMeetingSearch`, `DioMeetingFormats`, `BmltEndpoints`, `bmltOverrides`) with the exact query strings; verify with adapter unit tests against `BmltServerMimic` that assert the recorded URIs, `{}`, network failure and decode failure
- [ ] 7.2 Add `AppConfig` (reads the `BMLT_*` defines) and wire `bmltOverrides` into `productionOverrides`; verify with an app unit test on the parsed config
- [ ] 7.3 Add the `/listfull` and `/listfull/:municipality` routes, the `knownPaths` rule for the sub-route, `BackRule` parent handling and the side-menu prefix selection; verify with the shell unit tests and the acceptance tests from 3.3
- [ ] 7.4 Make the acceptance tests from groups 3.2 and 3.3 pass; verify with `./bin/na test acceptance`

## 8. Goldens and accessibility (D10)

- [ ] 8.1 Add `loadNaFonts`, `expectGolden` and `expectAccessible` to `na_testing`, and the Linux-only golden config; verify with a support unit test and one sample golden
- [ ] 8.2 Add goldens and `expectAccessible` for every slice 1 component and page state (card variants, list collapsed/expanded/filtered/empty, municipality list loading/loaded/empty/error, popover, range slider, section header, chip tones); verify with `./bin/na test widget`
- [ ] 8.3 Add goldens and `expectAccessible` for every slice 0 component (header bar, side menu, drawer, card, buttons, list row, option dialog, slider, indeterminate bar, fade clip, error state) and page (home, settings, contact, JFT); fix any accessibility failure they reveal; verify with `./bin/na test widget`

## 9. End to end and definition of done

- [ ] 9.1 Add the Patrol happy path `app/integration_test/meetings_search_test.dart` (open Meetings, tap a municipality, expand a day, open the formats popover) against `BmltServerMimic`; verify with `./bin/na test e2e --device <android emulator>`
- [ ] 9.2 Capture da/en Android screenshots of the municipality list, the meeting list and the popover into `docs/screenshots/meetings-search/`; add iOS screenshots to slice 0's open macOS task
- [ ] 9.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check` and confirm every floor is met
- [ ] 9.4 On archive, append the new legacy bugs (hour filter used the end time, `location_code_1`, substring TC/HY, stale list on second tap, stuck loader on failure, wrong Danish Bus/Train labels) to "Intentional deltas from the legacy app" in `openspec/specs/meetings-search/spec.md`
