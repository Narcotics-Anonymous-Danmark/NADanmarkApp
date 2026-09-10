# Media Player Specification

## Purpose

One global player plays audiobooks (a chapter queue with auto-advance) and
speaks (single files), keeps playing with the screen locked, exposes lock-screen
controls, remembers where the listener stopped, and can hand playback to a
Chromecast or an AirPlay route.

> Source: App/src/app/media-player/{media-player.models,media-player.service,resume-points.service,track-progress.service,audio-backend,cast.service,cast-backend,media-player.component}.ts, App/src/app/media-player/media-player.component.html, App/flutter/na_media_player/README.md, App/docs/cast-airplay-plan.md (legacy)

## Requirements

### Requirement: Playlist model

A playlist SHALL have `id`, `type` (book or speak), `title`, optional cover and
ordered `tracks` of `{id, title, url, durationLabel?}`. Books use the book id
(`basic-text`, `how-and-why`, `step-working-guides`) as playlist id; speaks use
the audio URL as playlist id and as the id of their single track. Duration
labels `m:ss` or `h:mm:ss` parse to seconds; anything else parses to 0.

#### Scenario: Duration label parsing

- **WHEN** labels `8:10`, `1:02:03` and `abc` are parsed
- **THEN** the results are 490, 3723 and 0 seconds

### Requirement: Single global player and status

There SHALL be exactly one player with state `{status, playlist, trackIndex,
position, duration}` where `status` is one of idle, loading, playing, paused.
The initial state is idle with no playlist. The docked player UI is visible
when the status is not idle.

#### Scenario: Idle at start

- **WHEN** the app starts
- **THEN** the player status is idle and the docked player is hidden

### Requirement: Play semantics

`play(playlist, trackIndex?)` SHALL: do nothing for an empty playlist; toggle
play/pause when the same playlist is active and the index is omitted or equals
the current index; otherwise persist the resume point of any other active
playlist, then start. With no index the start track is the resume point's
track (if its `trackId` still matches, else the track found by `trackId`, else
0) and the start position is the resume position; with an explicit index the
saved position is used only when the index equals the resume track. A start
position below 3 s SHALL become 0.

#### Scenario: Continue a book

- **WHEN** `basic-text` has a resume point at index 4, position 120 and `play(book)` is called
- **THEN** playback starts at chapter index 4, position 120

#### Scenario: Explicit other chapter starts at zero

- **WHEN** the resume point is at index 4 and `play(book, 6)` is called
- **THEN** chapter 6 starts at position 0

#### Scenario: Tiny resume position is dropped

- **WHEN** the resume position is 2 s
- **THEN** playback starts at 0

#### Scenario: Stale resume track is found by id

- **WHEN** the resume point has `trackIndex` 3 and `trackId` U but the track with id U is now at index 5
- **THEN** playback starts at index 5

### Requirement: Track start and status transitions

Starting a track SHALL release any previous engine, set status loading with the
track's parsed duration label as the initial duration, load and play the URL,
and become playing when the engine reports it is running; a pending start
position is applied at that moment. Position is polled every 1000 ms while
playing and the engine's duration replaces the label duration once known.

#### Scenario: Loading then playing

- **WHEN** a track starts
- **THEN** status is loading until the engine runs, then playing
- **AND** the seek to the start position happens when the engine runs

### Requirement: Controls

The player SHALL support pause, resume, toggle, stop, next/previous (books only,
disabled at the ends), `seekTo(seconds)` clamped to `[0, duration - 1]` when the
duration is known, and `seekBy(±)` with skip backward 15 s and skip forward 30 s.
Pause, seek and stop persist the resume point. Stop releases the engine and
returns to idle while keeping the resume point.

#### Scenario: Skip forward

- **WHEN** position is 100 and the user taps skip forward
- **THEN** the position becomes 130

#### Scenario: Seek is clamped

- **WHEN** duration is 300 and the user seeks to 400
- **THEN** the position becomes 299

#### Scenario: Stop keeps the resume point

- **WHEN** a speak is playing at 250 s and the user taps close
- **THEN** status is idle and the speak's resume point is 250 s

### Requirement: Auto-advance and end of playlist

When a track ends and a next track exists the player SHALL start it at 0. When
the last track ends the player SHALL clear the playlist's resume point and stop
without persisting. A playback error stops the player and persists the resume
point.

#### Scenario: Chapter ends and the next starts

- **WHEN** chapter index 4 of 97 ends
- **THEN** chapter index 5 starts at position 0

#### Scenario: Book finishes

- **WHEN** the last chapter ends
- **THEN** the book's resume point is removed and the player is idle

#### Scenario: Error stops and keeps the place

- **WHEN** the engine reports an error at 40 s
- **THEN** the player is idle and the resume point is 40 s

### Requirement: Resume points

A resume point is `{trackId, trackIndex, position (floor), duration? (floor,
only when > 0), updatedAt (ISO 8601)}`. It SHALL be saved on track start, at
most every 5000 ms while playing, on pause, seek, stop, app background, and
when switching playlists. Keys: `mediaResume.book.<bookId>` and
`mediaResume.speak.<audioUrl>` for the point, plus a denormalised index
`mediaResume.index.book` and `mediaResume.index.speak` mapping playlist id to
point so list pages can read all points in one call. Clearing a point removes
it from both. Malformed stored values (non-numeric `position` or `trackIndex`)
are ignored.

#### Scenario: Periodic save cadence

- **WHEN** a track plays for 12 s
- **THEN** the resume point has been saved at start and then at 5 s and 10 s (at most every 5 s)

#### Scenario: Index mirrors the point

- **WHEN** the resume point for speak URL U is saved
- **THEN** `mediaResume.speak.U` and `mediaResume.index.speak[U]` hold the same point

#### Scenario: Clearing removes both

- **WHEN** the point for `how-and-why` is cleared
- **THEN** `mediaResume.book.how-and-why` is gone and `mediaResume.index.book` has no `how-and-why` entry

### Requirement: Docked player UI

The docked player SHALL show: the track title and, under it, the playlist title
(or the cast status line); route buttons (AirPlay on iOS, Cast when available);
a close button (stop); the position, a seek slider (disabled while the duration
is unknown) and the duration or "--:--"; and controls previous (books only),
skip back 15, play/pause (spinner while loading), skip forward 30, next (books
only). While dragging the slider the drag position is shown; the seek is
committed on release. Times are `m:ss` or `h:mm:ss`. Accessibility labels:
"Play", "Pause", "Close player", "Previous chapter", "Next chapter", "Rewind 15
seconds", "Forward 30 seconds".

#### Scenario: Book shows chapter buttons

- **WHEN** a book plays
- **THEN** previous and next buttons are shown; previous is disabled on chapter 1

#### Scenario: Speak hides chapter buttons

- **WHEN** a speak plays
- **THEN** no previous/next buttons are shown

#### Scenario: Drag preview then commit

- **WHEN** the user drags the slider to 200 and releases
- **THEN** the displayed time follows the drag and a single seek to 200 is issued on release

### Requirement: Background playback and lock-screen controls

Playback SHALL continue with the screen off or the app in the background
(Android foreground service with media notification, iOS background audio
mode). Lock-screen / notification controls SHALL show the track title and
playlist title, the cover when available, play/pause, skip ±15/30, previous/next
for books, scrubbing and a close action; elapsed time is synced at least every
5000 ms and on every status change. Control events map to the player controls.
The Android notification permission is requested once, the first time playback
starts.

#### Scenario: Lock-screen pause

- **WHEN** the user taps pause on the lock screen
- **THEN** the player status becomes paused and the resume point is saved

#### Scenario: Headset toggle

- **WHEN** a headset play/pause event arrives while playing
- **THEN** playback pauses

### Requirement: Cast session state and availability

The Cast session SHALL expose `{available, connected, connecting, deviceName}`,
initially all false/none. The Cast button is shown when `available`,
`connected` or `connecting`; it is highlighted when connected and shows a
spinner while connecting. Tapping it opens the native device picker (or the
controller dialog when connected). The status line reads "Playing on <device>"
(Afspiller på <device>) when connected (device name falls back to "Chromecast")
and "Connecting to Chromecast…" while connecting. On a device without Google
Play Services or without a picker `available` stays false and no button is
shown.

#### Scenario: Button hidden without receivers

- **WHEN** no Cast device is on the network
- **THEN** no Cast button is rendered

#### Scenario: Connected state

- **WHEN** a session to "Living room" is connected
- **THEN** the button is highlighted and the status line reads "Playing on Living room"

### Requirement: Cast handoff

When the session becomes connected while a track is active the player SHALL
read the current position, restart the same track on the Cast engine at that
position, and re-pause if it was paused. When the session drops while casting
the same handoff happens back to the local engine. The Cast engine loads one
item at a time with `{url, contentType, title, artist = playlist title,
duration, position, autoplay}`; content type by extension: `.wav` →
`audio/wav`, `.m4a`/`.mp4` → `audio/mp4`, `.ogg`/`.oga` → `audio/ogg`, `.aac` →
`audio/aac`, else `audio/mpeg`. Receiver state maps to engine events: PLAYING →
running (once per item); IDLE + FINISHED → ended (only after PLAYING was seen);
IDLE + ERROR or load failure → error; IDLE + CANCELLED/INTERRUPTED → ignored.
Play/pause/seek issued before the receiver accepted the load are applied when
it does.

#### Scenario: Connect mid-track hands over at the same position

- **WHEN** a chapter plays locally at 300 s and a Cast session connects
- **THEN** the receiver loads the chapter URL with position 300 and local playback stops

#### Scenario: Disconnect returns to local playback

- **WHEN** casting at 420 s and the session ends
- **THEN** the local engine plays the same track from 420 s

#### Scenario: Paused state survives handoff

- **WHEN** the player is paused at 50 s and a session connects
- **THEN** the receiver loads at 50 s and is paused

#### Scenario: Previous item's FINISHED is ignored

- **WHEN** a new item is loaded and the receiver reports IDLE + FINISHED before PLAYING
- **THEN** no auto-advance happens

### Requirement: Local controls suppressed while casting

While casting the app SHALL not show its own media notification / lock-screen
controls (the Cast SDK shows its own) and SHALL restore them on handoff back to
local playback. The docked player keeps working as the remote control.

#### Scenario: One notification while casting

- **WHEN** a session connects during playback
- **THEN** the app's media notification is removed and only the Cast notification remains

### Requirement: AirPlay picker

On iOS the docked player SHALL show an AirPlay button that opens the system
route picker; the button is tinted primary while the current output route is
AirPlay. Audio already routes through the selected output; no handoff logic is
involved.

#### Scenario: AirPlay button on iOS only

- **WHEN** the docked player renders on Android
- **THEN** no AirPlay button is shown

#### Scenario: Active route tints the button

- **WHEN** the output route changes to an AirPlay device
- **THEN** the AirPlay button uses the primary colour

### Requirement: Progress labels shared by lists

List pages SHALL compute a progress label from a resume point as: nothing when
`position < 5` or when `position / duration > 0.995`; else "Continue from
<position>" plus " · <duration - position> left" when the duration is known;
and for the active track "Now playing · <position>[ / <duration>]".

#### Scenario: Continue label

- **WHEN** a point has position 65 and duration 600
- **THEN** the label is "Continue from 1:05 · 8:55 left" and the bar is 65/600

## Intentional deltas from the legacy app

- Legacy fell back to an HTML5 `<audio>` engine in the browser; the rewrite has one native engine plus the Cast engine.
- Legacy Android 13+ notification permission was requested through the local-notification plugin; the rewrite uses the platform permission API.
- Cover artwork on cast receivers stays deferred (local asset paths are not public URLs).
- The legacy `docs/media-player.md` referenced by the code did not exist; this spec is the contract.
