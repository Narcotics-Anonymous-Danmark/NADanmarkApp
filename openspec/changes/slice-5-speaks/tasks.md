# Tasks

## 1. Kernel (D2, D3, D4)

- [x] 1.1 Add `na_kernel/lib/src/speaks/` (`FeedText`, values, `Speak`, `SpeakDate`, `SpeakConvention`, `SpeakCatalog` builder) with `unorm_dart 0.3.3`; verify table tests for every text, convention, date, kind, title and meta scenario and the catalogue rules
- [x] 1.2 Add `SpeakGroupDto`, `SpeakEntryDto` and `SpeaksMapper` (`./bin/na gen json`); verify lenient scalars, dropped groups and entries, `{}` and non-list bodies

## 2. Port, builders and mimics (D2, D10)

- [x] 2.1 Add `SpeaksFeedPort` and its unbound provider; verify the unbound-port test lists it
- [x] 2.2 Add `WordPressMimic` (routes by `excerpt[]`, checks Basic auth, replies: groups, error, unreachable, malformed, held), `SpeaksFeedMimic` bound in `TestContainer`, the speak builders and the sample feed; verify with mimic unit tests

## 3. Acceptance tests first (red)

- [x] 3.1 Add `app/test_acceptance/support/speaks.dart` (pump at `/speaks` with a `WordPressMimic`, search, tap chips, open the panel, scroll)
- [x] 3.2 Write one `testWidgets` per speaks scenario in `app/test_acceptance/speaks/`; verify they pass once the page is wired (written alongside the page rather than strictly red first)

## 4. Adapter (D2)

- [x] 4.1 Create `adapter_wordpress` with `WordPressEndpoints`, `DioSpeaksFeed` and `wordpressOverrides`; verify against `WordPressMimic`

## 5. Feature use cases (D5, D6, D8)

- [x] 5.1 Create `feature_speaks` with `SpeaksCatalogLoader`; verify both feeds, one failing, both failing, cache, refresh keeping the catalogue
- [x] 5.2 Add `SpeakFiltersController`, `SpeakResumes`, `SpeakListing` and `SpeakRowView`; verify unit tests for debounce, toggles, reset, paging, year options, sorting, sections, continue list and row states

## 6. Design system (D9)

- [x] 6.1 Add `NaSearchField`, `NaSwipeActions`, `NaPullToRefresh`, `NaToggleChip`, `NaChipStrip`, `NaMessageBlock`, `NaSkeletonRow`, `NaToolbarButton` and `NaIcons.funnel`; verify widget tests, goldens and semantics

## 7. Page and wiring

- [x] 7.1 Build `SpeaksBody` and its parts; verify widget tests for loading, error, empty, loaded, filter panel and continue states
- [x] 7.2 Wire the route, `AppConfig.wordpress` and `wordpressOverrides` in the composition root; verify the acceptance tests from 3.2 pass
- [x] 7.3 Correct the speak rows in `docs/LEGACY_PARITY.md`; verify `./bin/na check arb`

## 8. Goldens and accessibility

- [x] 8.1 Add goldens and `expectAccessible` for the loaded list, the filter panel, the continue section, the error and the empty state

## 9. End to end and definition of done

- [x] 9.1 Add the Patrol test `app/integration_test/speaks_test.dart`; verify with `./bin/na test e2e --device <android emulator>`
- [x] 9.2 Capture da/en Android screenshots (list, filters, playing) into `docs/screenshots/speaks/`; captured on the `android-35` emulator with the sample feed (`SpeaksFeedMimic`), one speak pointed at a real Basic Text MP3 so the playing shots show real playback; iOS screenshots join slice 0's open macOS task
- [x] 9.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check` and confirm every floor is met

## 10. Regression: speak length and scrubbing

- [x] 10.1 Fix the load race: the player creates the `LoadToken` and passes it to `AudioEnginePort.load`, so `EngineLength` emitted while just_audio loads is no longer dropped (speaks have no duration label to fall back on, so length, "left", the play-head and continue bars stayed unknown and scrubbing was disabled)
- [x] 10.2 Make `AudioEngineMimic` report the length during `load` like just_audio; verify the player unit tests were red before the fix and green after
- [x] 10.3 Regression tests at every level: player unit (speak takes the engine length, scrubbing seeks and saves), adapter unit (length while loading carries the caller token), docked bar widget (speak shows 10:00 and a drag seeks), acceptance "A speak shows its length and can be scrubbed", Patrol speaks test on a real MP3 (length reported, tap in the middle of the scrubber seeks there)

## Workflow follow-up

- On archive, add the deltas listed at the end of `specs/speaks/spec.md`.
- Archive with `/opsx:archive slice-5-speaks` after the PR is merged.
