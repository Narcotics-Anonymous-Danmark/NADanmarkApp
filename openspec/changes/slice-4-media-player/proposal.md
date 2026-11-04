# Slice 4: media player, audiobooks and group readings

## Why

The three NA books read aloud are the app's second most used feature after
the meeting search. Members listen for hours, often with the screen locked,
and expect to continue where they stopped. This slice brings the one global
player, background playback with lock-screen controls, the Audiobooks pages
and the resume points. Users updating from the Ionic app keep their listening
positions. The Group readings page is small and has no dependencies, so it
ships in the same slice.

Speaks (slice 5) reuse the player and the resume points unchanged. Chromecast
and AirPlay (slice 9) plug into the same player later.

## What Changes

- **Media domain** (`na_kernel`):
  - playlists, tracks, durations, resume points and the player state;
  - the start rule (which track and position `play` starts at);
  - the progress rules shared by the list pages (book and chapter progress).
- **Resume points** stored under the legacy keys `mediaResume.<kind>.<id>`
  with the denormalised `mediaResume.index.<kind>`, through
  `KeyValueStorePort` and a kernel codec.
- **Ports**: `AudioEnginePort` (load, play, pause, seek, stop and an event
  stream) and `MediaSessionPort` (lock-screen metadata and remote commands).
- **`adapter_audio`** (new) on `just_audio`, `audio_session` and
  `audio_service`: the engine, the media session with a foreground service on
  Android, and book covers copied to files for the lock screen.
- **`feature_media_player`** (new library):
  - one `MediaPlayer` controller with the playback state machine, the resume
    rules and remote commands;
  - the docked player bar, shown by the shell above every page while
    something plays.
- **`feature_audiobooks`** (new): the Audiobooks list and one book page for
  the three books, with continue rows and progress.
- **`feature_readings`** (new): the Group readings page with its selector and
  coloured cards.
- **`adapter_assets`** (new): the bundled book and reading JSON, read through
  `AudiobooksPort` and `ReadingsPort`.
- **Legacy migration** of `mediaResume.book.*` and `mediaResume.speak.*`,
  with both indexes rebuilt from the imported points.
- **Native configuration**:
  - Android: `AudioServiceActivity`, the media playback foreground service,
    the media button receiver and their permissions;
  - iOS: the `audio` background mode.
- **Design system**: a playback scrubber, a thin progress bar, a spinner and
  the media icons.

Legacy behaviour not reproduced:
- The position was polled every second through the Cordova plugin. The
  engine now reports positions as a stream (about once a second).
- The Audiobooks list and the book pages each re-read resume points on every
  visit. Both now watch one shared resume-point state that the player keeps
  current.
- The Group readings selector was an Ionic popover with the hard-coded
  placeholder "Vælg venligst". It is now the option sheet used by Settings;
  the row shows only the chosen title, without a label.
- Reading texts were inline HTML. They are now a structured asset.

## Non-goals

- Chromecast and AirPlay (slice 9). The docked player shows no route
  buttons until then.
- Speaks (slice 5). The player and the resume points already support them.
- Downloading books for offline listening, and playback speed.
- Resuming a book from Home (slice 6 composes Home).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `media-player`:
  - the player state without nullable fields;
  - positions reported by the engine instead of polled;
  - resume-point storage format and save cadence measured by the clock;
  - the docked player without route buttons until slice 9;
  - the notification permission through the platform API.
- `audiobooks`:
  - where the book data and covers are bundled;
  - a load failure state;
  - the Back button and system back;
  - refreshes driven by the shared resume-point state.
- `readings`:
  - the structured asset;
  - the option-sheet selector;
  - the page background in the reading's colour.
- `legacy-migration`: the resume-point import and how its keys are counted.
- `settings`: settings are explicitly "not loaded" until start-up loads them,
  and a failed write keeps the last settings in use instead of falling back to
  the defaults (part of the no-`late` / explicit-initial-state rules adopted
  in this slice, design D12). Meetings nearby likewise shows its radius slider
  only once the radius has been read from the settings.

## Impact

- **New packages**:
  - `packages/features/feature_media_player`, `feature_audiobooks`,
    `feature_readings`
  - `packages/adapters/adapter_audio`, on `just_audio`, `audio_session`,
    `audio_service` and `path_provider` with exact pinned versions
  - `packages/adapters/adapter_assets`, with `basic-text.json`,
    `how-and-why.json`, `step-working-guides.json` and `readings.json`
- **Extended packages**:
  - `na_kernel`: media and readings types, resume codec, book and reading
    DTOs, legacy resume translator
  - `na_ports`: `AudioEnginePort`, `MediaSessionPort`, `AudiobooksPort`,
    `ReadingsPort`
  - `na_design`: `NaScrubber`, `NaProgressBar`, `NaSpinner`, media icons
  - `na_l10n`: seek, loading and failure texts; playback time format
  - `na_testing`: `AudioEngineMimic`, `MediaSessionMimic`, book and reading
    builders, resume builders, legacy dump resume entries
  - `feature_shell`: the docked player binding
  - `feature_legacy_migration`: the resume import step
  - `app`: routes, overrides, startup, acceptance tests, a Patrol test
- **Native**: `AndroidManifest.xml`, `MainActivity.kt`, `Info.plist`.
- **Configuration**: `coverage.yaml` floors for the five new packages;
  `docs/LEGACY_PARITY.md` rows for the player, the books and the readings.
