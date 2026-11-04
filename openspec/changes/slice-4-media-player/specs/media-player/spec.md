# Spec Delta

## MODIFIED Requirements

### Requirement: Playlist model

A playlist SHALL have `id`, `kind` (book or speak), `title`, a cover (a
bundled image or none) and ordered `tracks` of `{id, title, url,
durationLabel}`. Books use the book id (`basic-text`, `how-and-why`,
`step-working-guides`) as playlist id; speaks use the audio URL as playlist
id and as the id of their single track. Duration labels `m:ss` or `h:mm:ss`
parse to a known length; anything else is an unknown length.

#### Scenario: Duration label parsing

- **WHEN** labels `8:10`, `1:02:03`, `13:53:58`, `abc` and an empty label are parsed
- **THEN** the results are 490 s, 3723 s, 50038 s, unknown and unknown

### Requirement: Single global player and status

There SHALL be exactly one player. It is either idle, or active with
`{status, playlist, trackIndex, position, length}` where `status` is one of
loading, playing, paused and `length` is known or unknown. The initial state
is idle. The docked player is shown above the bottom edge of every page while
the player is active and the page content is never covered by it.

#### Scenario: Idle at start

- **WHEN** the app starts
- **THEN** the player is idle and the docked player is hidden

#### Scenario: Docked player follows playback across pages

- **WHEN** a chapter plays and the user opens Settings from the menu
- **THEN** the docked player is still shown with the chapter title

### Requirement: Track start and status transitions

Starting a track SHALL release any previous engine item, set status loading
with the track's label length as the initial length, load the URL at the
start position and play it, and become playing when the engine reports it is
running. While playing the engine reports the position about once a second
and the engine's length replaces the label length once known. Events from a
released item are ignored.

#### Scenario: Loading then playing

- **WHEN** a track starts at 120 s
- **THEN** status is loading until the engine runs, then playing
- **AND** the engine was loaded at 120 s

#### Scenario: Engine length replaces the label

- **WHEN** a chapter labelled `8:10` starts and the engine reports a length of 491 s
- **THEN** the player length is 491 s

### Requirement: Resume points

A resume point is `{trackId, trackIndex, position (whole seconds, floored),
duration (whole seconds, only when the length is known and > 0), updatedAt
(ISO 8601 UTC)}`. It SHALL be saved when a track starts, on an engine position
report when at least 5 s have passed on the clock since the last save, on
pause, seek, stop, playback error, when the app goes to the background, and
when switching to another playlist. Keys: `mediaResume.book.<bookId>` and
`mediaResume.speak.<audioUrl>` for the point, plus a denormalised index
`mediaResume.index.book` and `mediaResume.index.speak` mapping playlist id
to point so list pages can read all points in one call. Values are stored as
JSON text. Clearing a point removes it from both. Malformed stored values
(missing or non-numeric `position` or `trackIndex`, unreadable JSON) are
ignored.

#### Scenario: Periodic save cadence

- **WHEN** a track plays for 12 s
- **THEN** the resume point has been saved at start and then at 5 s and 10 s (at most every 5 s)

#### Scenario: Index mirrors the point

- **WHEN** the resume point for speak URL U is saved
- **THEN** `mediaResume.speak.U` and `mediaResume.index.speak[U]` hold the same point

#### Scenario: Clearing removes both

- **WHEN** the point for `how-and-why` is cleared
- **THEN** `mediaResume.book.how-and-why` is gone and `mediaResume.index.book` has no `how-and-why` entry

#### Scenario: Malformed point is ignored

- **WHEN** `mediaResume.book.basic-text` holds `{"trackIndex":"x","position":12}` and the book is played
- **THEN** playback starts at chapter index 0, position 0

#### Scenario: Background saves the place

- **WHEN** a chapter plays at 42 s and the app goes to the background
- **THEN** the book's resume point is 42 s

### Requirement: Docked player UI

The docked player SHALL show: the track title and, under it, the playlist
title; a close button (stop); the position, a seek slider (disabled while the
length is unknown) and the length or "--:--"; and controls previous (books
only), skip back 15, play/pause (spinner while loading), skip forward 30,
next (books only). While dragging the slider the drag position is shown; the
seek is committed on release. Times are `m:ss` or `h:mm:ss`. Accessibility
labels: "Play", "Pause", "Close player", "Previous chapter", "Next chapter",
"Rewind 15 seconds", "Forward 30 seconds", "Playback position" for the
slider and "Loading" for the spinner. Route buttons (Cast, AirPlay) are added
in slice 9.

#### Scenario: Book shows chapter buttons

- **WHEN** a book plays
- **THEN** previous and next buttons are shown; previous is disabled on chapter 1

#### Scenario: Speak hides chapter buttons

- **WHEN** a speak plays
- **THEN** no previous/next buttons are shown

#### Scenario: Drag preview then commit

- **WHEN** the user drags the slider to 200 and releases
- **THEN** the displayed time follows the drag and a single seek to 200 is issued on release

#### Scenario: Unknown length

- **WHEN** a speak without a duration label is loading
- **THEN** the length reads "--:--" and the slider is disabled

### Requirement: Background playback and lock-screen controls

Playback SHALL continue with the screen off or the app in the background
(Android foreground service with media notification, iOS background audio
mode). Lock-screen / notification controls SHALL show the track title and
playlist title, the cover when the playlist has one, play/pause, skip ±15/30,
previous/next for books, scrubbing and a close action; the elapsed time is
published on every status change, every seek and at least every 5 s while
playing. Remote commands (lock screen, notification, headset, car) map to the
player controls. On Android 13+ the notification permission is requested
once per app run, the first time playback starts; playback continues whether
or not it is granted.

#### Scenario: Lock-screen pause

- **WHEN** the user taps pause on the lock screen
- **THEN** the player status becomes paused and the resume point is saved

#### Scenario: Headset toggle

- **WHEN** a headset play/pause event arrives while playing
- **THEN** playback pauses

#### Scenario: Lock-screen metadata for a book

- **WHEN** chapter 1 of Basic Text starts
- **THEN** the media session shows the chapter title, "Basis Tekst", the Basic Text cover, and previous disabled, next enabled

#### Scenario: Permission asked once

- **WHEN** two chapters are started one after the other
- **THEN** the notification permission was requested once
