# Tasks

## 1. Kernel (D2, D3, D7, D8, D9)

- [x] 1.1 Add `na_kernel/lib/src/media/`: values, `PlaylistKind`, `MediaLength`, `DurationLabel`, `PlaylistCover`, `MediaTrack`, `MediaPlaylist`, `ResumePoint`, `ResumeState`, `PlayerState`, `TrackStart`, `TrackProgress`, `BookProgress`; verify with unit tests for label parsing, every start-rule scenario and the progress examples of both specs
- [x] 1.2 Add `ResumePointDto`, `ResumeIndexDto` and `ResumeCodec` with `ResumeKeys` (`./bin/na gen json`); verify round trip, lenient numbers, malformed values ignored and the key scheme
- [x] 1.3 Add `na_kernel/lib/src/library/` (`AudiobookId`, `Audiobook`, `Chapter`, `Reading`, `ReadingBlock`, `TextSpan`) with `AudiobookDto`, `ReadingDto` and their mappers; verify mapper unit tests (missing fields, bad colours, unknown block kinds)
- [x] 1.4 Add `LegacyStoreDumpDto.mediaResume` (`readValue`) and `LegacyResumeTranslator`; verify one unit test per legacy-migration delta scenario plus object/text values

## 2. Ports, builders and mimics (D4, D13)

- [x] 2.1 Add `AudioEnginePort`, `MediaSessionPort`, `AudiobooksPort`, `ReadingsPort` and their unbound providers; verify the unbound-port unit test lists them
- [x] 2.2 Add `AudioEngineMimic` (scripted running delay, length, failures, position ticks on `TestTime`), `MediaSessionMimic` (records shown tracks and playback, emits commands), `AudiobooksMimic`, `ReadingsMimic`, bound by default in `TestContainer`; add builders `aTrack`, `aPlaylist`, `aResumePoint`, `anAudiobook`, `aReading` and `mediaResume` on `aLegacyStoreDump`; verify with mimic unit tests

## 3. Acceptance tests first (red)

- [x] 3.1 Extend `AppHarness` with `engine`, `session` and helpers in `app/test_acceptance/support/media.dart` (open a book, tap a chapter, run the engine, read the docked bar)
- [x] 3.2 Write one `testWidgets` per scenario of the four deltas in `app/test_acceptance/{media_player,audiobooks,readings,legacy_migration}/`; verify they fail because the features are missing

## 4. Adapters (D5, D7, D8)

- [x] 4.1 Create `adapter_assets` with the three legacy book JSON files and `readings.json` (generated once from the legacy template by a scratchpad script); implement `AssetAudiobooks` and `AssetReadings`; verify against `RepoAssetBundle` (counts, totals, titles, colours, 12 + 12 items) and a missing asset
- [x] 4.2 Create `adapter_audio` pinning the D5 versions; implement `JustAudioEngine`, `AudioServiceSession`, `ArtworkFiles` and `audioOverrides`; verify against a `JustAudioPlatform` mimic (load with start position, running once per item, length, positions, completed, errors, stale tokens), the handler overrides and published states, and artwork copying to a temp directory

## 5. Feature use cases (D3, D6)

- [x] 5.1 Create `feature_media_player` with `ResumePoints`; verify save/clear/index over `KeyValueStoreMimic`, malformed values and the loaded library state
- [x] 5.2 Implement `MediaPlayer`; verify one unit test per media-player scenario (play semantics, transitions, controls, auto-advance, finish, error, cadence, background, remote commands, permission once, session metadata)
- [x] 5.3 Add progress texts (`TrackProgressText`, `BookProgressText`) and `PlaybackTimeFormat`; verify `en`/`da` labels

## 6. Design system

- [x] 6.1 Add `NaScrubber` (drag preview, commit on release, disabled state, slider semantics), `NaProgressBar`, `NaSpinner` and the media icons; verify widget tests, goldens and semantics

## 7. Pages and wiring (D6, D7, D8, D11)

- [x] 7.1 Add the D11 keys to both ARB files, regenerate with `./bin/na gen l10n`, and correct `docs/LEGACY_PARITY.md`; verify with `./bin/na check arb`
- [x] 7.2 Build `DockedPlayerBar` and bind `dockedPlayerProvider`; verify widget tests per status and kind
- [x] 7.3 Create `feature_audiobooks` with the covers, `AudiobooksBody` and `BookBody`; verify widget tests (rows, progress, continue section, play icons, failure)
- [x] 7.4 Create `feature_readings` with `ReadingsBody`; verify widget tests (default, selection, cancel, colours, failure)
- [x] 7.5 Wire the routes, `assetsOverrides` and `audioOverrides` in the composition root, `playerLifecycleProvider` in `AppStartup`; verify the acceptance tests from 3.2 pass with `./bin/na test acceptance`
- [x] 7.6 Add `_importResumePoints` to `LegacyMigration`; verify feature unit tests and the legacy-migration acceptance tests

## 8. Native configuration (D10)

- [x] 8.1 Android: `AudioServiceActivity`, permissions, service and receiver; verify on the emulator that a chapter keeps playing with the screen off, the notification shows the controls and the cover, and pause on the notification pauses the docked player
- [x] 8.2 iOS: `UIBackgroundModes` `audio`; add "build iOS, play a chapter, lock the screen, use the lock-screen controls" to slice 0's open macOS task

## 9a. No late, explicit initial states (D12)

- [x] 9a.1 Add `na_lints/avoid_late` with fixtures; remove every `late` in lib, tests and tools; verify custom_lint reports nothing
- [x] 9a.2 Replace placeholder and option-as-default fields with sealed states (player, engine, mimic, design drafts, docked bar views, settings, nearby radius and search runs); verify the affected unit, widget and acceptance tests
- [x] 9a.3 Record the rules in `docs/CODING_GUIDELINES.md`, `AGENTS.md`, the plan and memory

## 9. Goldens and accessibility

- [x] 9.1 Add goldens and `expectAccessible` for the docked bar (book loading, book playing, speak paused), the audiobooks list with progress, the book page with a continue row, and two readings; verify with `./bin/na test widget`

## 10. End to end and definition of done

- [x] 10.1 Add the Patrol test `app/integration_test/audiobooks_test.dart`; verify with `./bin/na test e2e --device <android emulator>`
- [x] 10.2 Capture da/en Android screenshots (list, book page, docked player, readings) into `docs/screenshots/audiobooks/` and `docs/screenshots/readings/`; add iOS screenshots to slice 0's open macOS task
- [x] 10.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check` and confirm every floor is met

## Workflow follow-up

- On archive, add to "Intentional deltas from the legacy app" in `openspec/specs/media-player/spec.md`:
  - positions come from the engine's stream instead of a 1 s poll
  - resume values are JSON text; malformed JSON is ignored like a malformed point
  - the docked player has no route buttons until slice 9
- On archive, add to `openspec/specs/audiobooks/spec.md` deltas: progress follows one shared resume-point state instead of re-reading on every visit; a book that cannot be read shows an error
- On archive, add to `openspec/specs/readings/spec.md` deltas: the selector is the Settings option sheet with no "Vælg venligst" label; the page background is the reading's colour
- On archive, add to `openspec/specs/legacy-migration/spec.md` deltas: legacy resume indexes are never read
- On archive, fold the `settings` delta into `openspec/specs/settings/spec.md` and note in `openspec/specs/meetings-search/spec.md` that the nearby radius slider appears once the radius is read
- Archive with `/opsx:archive slice-4-media-player` after the PR is merged.
