# Design

## Context

Earlier slices provide:
- `KeyValueStorePort` with kernel codecs for structured values, and
  `SettingsPort`;
- `Clock`, `Ticker` and `Scheduler` with `TestTime` fakes that move time,
  fire timers and ticks in order;
- `NotificationsPort.ensureAccess()`, which asks for `POST_NOTIFICATIONS` on
  Android 13+ (slice 3);
- `EventBus`;
- the shell's `dockedPlayerProvider` (`NoPlayer` / `PlayerDocked`), which
  already reserves space under every page, and `BookRoute` with the three
  book paths and the back rule to `/audiobooks`;
- the legacy-store plugin, which dumps every `_ionickv` key with structured
  values, including `mediaResume.*`;
- `LegacyMigration` with import steps for settings, the formats cache and
  cleantime;
- `adapter_jft` as the pattern for a bundled JSON asset behind a port;
- `showNaOptionDialog` + `NaListRow` (the Settings selectors), `NaCard`,
  `NaIconButton`, golden and accessibility helpers;
- the legacy ARB keys for every player and book text (`player*`,
  `chapters`, `bookChapterOf`, `basicText`, `howAndWhy`,
  `stepWorkingGuides`, `audiobooks`, `grc`, `back`).

What is missing:
- Every media type, the engine and the media session.
- The book data, the covers and the reading texts.
- A scrubber, a progress bar and a spinner in the design system.
- The DTO fields and the translator for the legacy resume keys.

Constraints:
- `LayerRules`: features may import only the bridge features
  `feature_meetings` and `feature_media_player`. The shell and the book pages
  therefore depend on `feature_media_player`, never the other way round.
- Adapters may not import `na_l10n` or `na_design`.
- `audio_service` needs the Android activity to be an
  `AudioServiceActivity` and must be initialised once before `runApp`.
- `just_audio` reports positions on a stream. The rules forbid polling where
  a stream exists.

## Goals / Non-Goals

**Goals:**
- The playback state machine is plain Dart in `feature_media_player`, driven
  only through ports, so every scenario of the spec runs as a unit test with
  `AudioEngineMimic`, `MediaSessionMimic` and `TestTime`.
- The resume rules and progress maths are pure kernel functions.
- The adapters are thin translations of plugin APIs, tested against mimics
  of the plugins' platform interfaces.

**Non-Goals:**
- Cast and AirPlay. `AudioEnginePort` is shaped so a Cast engine can
  implement it in slice 9 (load one item, play, pause, seek, events).
- Gapless playback. Each chapter is loaded on its own, as in the legacy app.

## Decisions

### D1 Packages

- `na_kernel/lib/src/media/`: media types and pure rules (D2), the resume
  codec and legacy translator in `lib/src/boundary/` (D3, D9).
- `na_kernel/lib/src/library/`: audiobook and reading types, plus their
  asset DTOs and mappers in `lib/src/boundary/` (D7, D8).
- `na_ports`: `AudioEnginePort`, `MediaSessionPort` (D4),
  `AudiobooksPort`, `ReadingsPort` (D7, D8).
- `adapter_audio` (new): `JustAudioEngine`, `AudioServiceSession`,
  `ArtworkFiles`, `audioOverrides(...)` (D5).
- `adapter_assets` (new): `AssetAudiobooks`, `AssetReadings`,
  `assetsOverrides({required AssetBundle bundle})`.
- `feature_media_player` (new, bridge): `ResumePoints`, `MediaPlayer`,
  `DockedPlayerBar`, progress texts (D6).
- `feature_audiobooks` (new): `AudiobooksBody`, `BookBody`, covers.
- `feature_readings` (new): `ReadingsBody`.
- `feature_shell`: `dockedPlayerProvider` watches the player (D6).
- `feature_legacy_migration`: `_importResumePoints` (D9).

### D2 Kernel media types

- Values: `PlaylistId`, `TrackId`, `TrackTitle`, `PlaylistTitle`,
  `AudioUrl` (a `Uri`), `TrackIndex`, `AssetKey`, `DurationLabel`.
- `PlaylistKind { book, speak }` with the storage code.
- `MediaLength` sealed: `KnownLength(Duration)` / `UnknownLength()`.
  `DurationLabel.length` parses `m:ss` or `h:mm:ss`; anything else is
  `UnknownLength`.
- `PlaylistCover` sealed: `BundledCover(AssetKey)` / `NoCover()`.
- `MediaTrack {id, title, url, label}` and `MediaPlaylist {id, kind, title,
  cover, tracks}`.
- `ResumePoint {trackId, trackIndex, position, length, updatedAt}` with the
  position floored to whole seconds; `ResumeState` sealed: `NotStarted()` /
  `ResumeAt(point)`.
- `PlayerState` sealed: `PlayerIdle()` / `PlayerActive {playlist,
  trackIndex, status, position, length}` with `ActiveStatus {loading,
  playing, paused}`. There is no nullable playlist.
- `TrackStart.resolve({playlist, resume, requested})` implements the start
  rule: the resume track by index when its id still matches, else by id,
  else none; the start position only for that track; below 3 s it becomes 0.
  `requested` is sealed: `ContinueListening()` / `StartTrack(index)`.
- `TrackProgress.ofResume` / `TrackProgress.live` and `BookProgress.of`
  return sealed results (`NoProgress`, `ResumeProgress`, `LiveProgress`,
  `SavedBookProgress`, `LiveBookProgress`) with a `ProgressFraction` that is
  `KnownFraction(double)` or `UnknownFraction()`. Texts are added by the
  feature.

### D3 Resume-point storage

Keys stay those of the legacy app: `mediaResume.<kind>.<playlistId>` for the
point and `mediaResume.index.<kind>` for the index. Values are JSON text
because `KeyValueStorePort` stores strings: `{trackId, trackIndex, position,
duration?, updatedAt}` and `{<playlistId>: point}`. `ResumePointDto` uses
`LenientInt`, so `"12"` and `12.0` still read. A value whose `trackIndex` or
`position` is missing or not a number is ignored, as in the legacy app.

`ResumePoints` (a `Notifier<ResumeLibrary>` in `feature_media_player`) is
the only writer:
- `pointFor(kind, id)` reads the point key;
- `save` writes the point, then reads, merges and writes the index;
- `clear` removes the point and its index entry;
- its state holds both indexes, loaded once and kept current by `save` and
  `clear`, so the list pages watch it instead of re-reading storage.

### D4 Ports

```dart
abstract interface class AudioEnginePort {
  Stream<EngineEvent> get events;
  Future<void> load({required EngineItem item, required Duration startAt});
  Future<void> play();
  Future<void> pause();
  Future<void> seek({required Duration position});
  Future<void> release();
}

abstract interface class MediaSessionPort {
  Stream<RemoteCommand> get commands;
  Future<void> show({required SessionTrack track, required SessionPlayback playback});
  Future<void> update({required SessionPlayback playback});
  Future<void> hide();
}
```

- `EngineEvent` sealed: `EngineRunning`, `EngineLength(Duration)`,
  `EnginePosition(Duration)`, `EngineEnded`, `EngineFailed(detail)`. Every
  event carries the `LoadToken` of the item it belongs to, so late events
  from a released item are dropped by the player.
- `RemoteCommand` sealed: play, pause, toggle, next, previous, skip forward,
  skip backward, seek to, stop.
- `SessionTrack {title, album, cover, length, navigation}` with
  `ChapterNavigation {previous, next}` as two `NaAvailability`-like enums;
  `SessionPlayback {status, position}`.

### D5 Adapter

Versions (exact): `just_audio 0.10.6`, `audio_service 0.18.19`,
`audio_session 0.2.4`, `path_provider 2.1.5`.

- `JustAudioEngine` owns one `AudioPlayer`. `load` calls
  `setAudioSource(AudioSource.uri(url), initialPosition: startAt)` and
  bumps the token. Events:
  - `EngineRunning` the first time `playing && ready` is seen per item;
  - `EngineLength` from `durationStream`;
  - `EnginePosition` from `createPositionStream(minPeriod: 1 s, maxPeriod:
    1 s)`;
  - `EngineEnded` on `ProcessingState.completed`;
  - `EngineFailed` for `PlayerException`, `PlayerInterruptedException` and
    `PlatformException`.
  The audio session is configured with `AudioSessionConfiguration.speech()`
  so calls and navigation prompts pause or duck playback.
- `AudioServiceSession extends BaseAudioHandler with SeekHandler`. Its
  overrides (`play`, `pause`, `stop`, `skipToNext`, `fastForward`, `seek`,
  `click` for headsets…) only push `RemoteCommand`s. `show`/`update` publish
  `mediaItem` and `playbackState` (controls, compact actions, position with
  speed 1 while playing so the OS extrapolates). `hide` publishes an idle
  state, which stops the foreground service.
- `ArtworkFiles` copies a bundled cover once into the cache directory and
  hands `audio_service` a `file://` URI.
- `audioOverrides({required AudioEnginePort engine, required MediaSessionPort
  session})` binds the ports. The composition root creates the
  `AudioServiceSession` through `AudioService.init` with channel
  `dk.nadanmark.app.audio`, `androidStopForegroundOnPause: true`.

### D6 Feature: player and docked bar

`MediaPlayer extends Notifier<PlayerState>` keeps the legacy service's
behaviour:
- `play({playlist, request})`: same playlist and same or no index toggles;
  otherwise it saves the point of another active playlist, resolves the
  start with `TrackStart`, and starts the track.
- Starting a track: release, state `loading` with the label length, `load`,
  `play`, save the point, show the session. The first time per run it calls
  `NotificationsPort.ensureAccess()` without waiting for the answer.
- Engine events update the state; positions save the point when
  `Clock.now()` is at least 5 s after the last save and update the session
  at the same cadence.
- `pause`, `seekTo`, `stop`, a playlist switch and `AppLifecycleState.paused`
  save the point. The last track ending clears it and stops without saving;
  an engine failure stops and saves.
- Remote commands map one to one to these methods.

`playerLifecycleProvider` registers an `AppLifecycleListener` and is read at
start-up. `dockedPlayerProvider` in the shell becomes `PlayerDocked(player:
DockedPlayerBar(), height: DockedPlayerBar.height)` while the player is
active, else `NoPlayer`. `DockedPlayerBar` is split into the title block,
the close button, the scrubber row and the controls row, each a small
`ConsumerWidget` watching a `select`ed slice of the state. The scrubber's
drag preview lives inside `NaScrubber` (a bridge widget), which reports only
the committed value.

### D7 Audiobooks

- `AudiobookId { basicText, howAndWhy, stepWorkingGuides }` carries the
  playlist id, the asset name, the cover asset and the total duration label
  from the legacy page. A unit test asserts each label equals the sum of the
  chapter labels.
- `Audiobook {id, title, chapters}` with `Chapter {title, url, label}`, read
  by `AudiobooksPort.load({required AudiobookId book})` from
  `packages/adapter_assets/assets/books/<id>.json`, copied unchanged from
  the legacy app (including its `bookAuhtor` typo, which is ignored).
- `audiobookProvider` (family by id) holds `LoadResult<Audiobook>`.
- `AudiobooksBody` rows: cover, title from ARB, clock line with the total
  duration, and for a book with progress a `NaProgressBar` and the label.
- `BookBody(book)`: cover 150 × 150, the continue section and the chapter
  rows. A chapter tap calls `play` with `StartTrack(index)`.
- The app maps `BookRoute` to `AudiobookId`; the back rule exists already.

### D8 Readings

`readings.json` holds seven readings `{title, heading, background, blocks}`.
A block is a `paragraph`, a `numbered` list or a `hanging` paragraph; its
text is a list of spans with an optional `emphasis` flag (step 3's "som vi
opfattede Ham" is italic). The asset is produced once from the legacy
template by a throwaway script in the session scratchpad, and a unit test
checks the seven titles, the colours and the 12 + 12 list items.
`ReadingsBody` shows a label-less `NaSelectRow` opening `showNaOptionDialog`,
then the reading card on the reading's colour. Reading texts are never
translated.

### D9 Legacy migration

`LegacyStoreDumpDto` gains `mediaResume`, read with `@JsonKey(readValue:)`
from every top-level key that starts with `mediaResume.book.` or
`mediaResume.speak.` (values may be objects or JSON text). The two index
keys are not read. `LegacyResumeTranslator` keeps entries whose
`trackIndex` and `position` are numbers. `_importResumePoints` writes each
kept point and the two rebuilt indexes, never overwriting an existing point.
Counting: each kept point key counts as imported, each dropped one as
skipped; the legacy index keys are not counted, since they are derived.

### D10 Native configuration

- Android: `MainActivity : AudioServiceActivity()`; permissions
  `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`;
  the `com.ryanheise.audioservice.AudioService` service with
  `foregroundServiceType="mediaPlayback"` and the `MediaButtonReceiver`.
- iOS: `UIBackgroundModes` = `audio` in `Info.plist`.

### D11 Localisation

New keys (da + en): `playerSeek` (slider label), `playerLoading`,
`playerUnknownTime` ("--:--" read as "Unknown duration"),
`audiobookCover`, `audiobooksLoadFailed`, `readingsLoadFailed`. The Group
readings selector has no label (the legacy "Vælg venligst" is dropped); it
shows the chosen title in a `NaSelectRow` and the sheet title is `grc`.
`PlaybackTimeFormat` in `na_l10n` formats `m:ss` / `h:mm:ss`.
`docs/LEGACY_PARITY.md` rows `AUDIOBOOKS`/`GRC` are corrected to the real
ARB keys.

### D12 No late, explicit initial states

Decided during this slice and applied to the whole codebase: no `late`
(lint `na_lints/avoid_late`) and no field that starts on a placeholder or on
one of the real options. Notifiers read ports through getters over `ref`;
debouncers live in auto-dispose providers the controller watches; dialogs get
their controllers from the `show…` function; drafts in bridge widgets are
sealed (`_WidgetValue` / `_LocalValue`, `_NotDragging` / `_Dragging`,
`_AtInitial` / `_Turned`); `LoadToken` is an identity object; the player's
last save is `_NeverSaved` / `_SavedAt`; the engine item is `_NoItem` /
`_LiveItem`; the docked bar parts select `_NoTitles` / `_Titles` and friends
instead of inventing idle values; the spinner and the loading bar use
`RepeatingAnimationBuilder` and are stateless.

### D13 Tests

- Kernel: label parsing, start rule, progress rules, codec and translator
  tables.
- Player: one unit test per media-player scenario over the mimics and
  `TestTime`.
- Adapters: `JustAudioEngine` against a `JustAudioPlatform` mimic,
  `AudioServiceSession` by calling the handler overrides and reading its
  streams, `ArtworkFiles` with a temp directory, `AssetAudiobooks` and
  `AssetReadings` against `RepoAssetBundle`.
- Widgets: docked bar per status, scrubber, progress bar, list rows, book
  page, readings card, with goldens and `expectAccessible`.
- Acceptance: one test per scenario of the four deltas.
- Patrol: open Audiobooks, open Basic Text, start chapter 1, see the docked
  player, pause, close; open Group readings and pick a reading.

## Risks / Trade-offs

- Android 14 foreground-service rules: the service type `mediaPlayback` and
  its permission are declared; the service starts only from a user gesture
  (play), which Android allows.
- `audio_service` replaces the activity class. A cleantime notification tap
  still opens the app, since `AudioServiceActivity` is a `FlutterActivity`.
- `just_audio` reports `EngineRunning` only after buffering. A slow network
  keeps the spinner up, as the legacy app did.
- Book JSON files are copied unchanged; if the server moves a file the
  chapter fails to load and the player stops with the place saved.

## Migration Plan

Resume points keep their keys, so a user who updates continues where they
stopped. The import runs inside the existing one-time migration.
