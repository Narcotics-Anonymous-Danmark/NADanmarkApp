# Audiobooks Specification

## Purpose

Audiobooks lists the three Danish NA books read aloud and lets the user play
chapters through the global media player, continue where they left off, and see
progress per book and per chapter.

> Source: App/src/app/pages/audiobooks/audiobooks.page.{ts,html}, App/src/app/pages/basic-text/*, App/src/app/pages/how-and-why/*, App/src/app/pages/step-working-guides/*, App/src/app/providers/{basic-text,how-and-why,step-working-guides}.service.ts, App/src/assets/data/{basic-text,how-and-why,step-working-guides}.json (legacy)

## Requirements

### Requirement: The three books

The app SHALL bundle three books, each as a JSON asset with `bookTitle`,
`bookEdition`, `bookAuthor` and `chapters[]` of `{title, url, duration}`
(`duration` as `m:ss` or `h:mm:ss`):

| Id | Route | Title (Danish) | Chapters | Total duration | Cover |
|---|---|---|---|---|---|
| `basic-text` | `/basic-text` | Basic Text (Basis Tekst) | 97 | 13:53:58 | `assets/img/audiobooks/basic-text.png` |
| `how-and-why` | `/how-and-why` | It Works: How and Why (Det Virker: Hvordan og Hvorfor) | 39 | 06:11:37 | `assets/img/audiobooks/how-and-why.png` |
| `step-working-guides` | `/step-working-guides` | The NA Step Working Guides (Vejledninger i Trinarbejde) | 13 | 05:03:49 | `assets/img/audiobooks/step-working-guides.png` |

Chapter audio URLs are absolute `https://www.nadanmark.dk/wp-content/uploads/…`
MP3 files.

#### Scenario: Chapter counts

- **WHEN** the three book assets are loaded
- **THEN** they contain 97, 39 and 13 chapters respectively

### Requirement: Audiobooks list

The Audiobooks page (title "Audiobooks" (Lydbøger)) SHALL list the three books
in the order above as rows with cover thumbnail, title, a clock line with the
total duration, and, when the book has progress, a progress bar and a label.
Tapping a row opens the book page. A row with progress uses the light row colour.

#### Scenario: List shows three books with durations

- **WHEN** the Audiobooks page opens
- **THEN** three rows are shown reading "13:53:58", "06:11:37" and "05:03:49"

### Requirement: Book progress

A book SHALL have progress when it has a resume point (or is currently playing) at a
chapter index within range, except when the index is 0 and the position is below
5 s. Progress is `elapsed / total` where `total` is the sum of all chapter
durations and `elapsed` is the sum of the durations of the chapters before the
resume chapter plus the position in it, capped at `total`. The label is
"Chapter <i> of <n>[ · <time left> left]" for a saved point and "Now playing ·
Chapter <i> of <n>" while the book is playing. `<i>` is 1-based.

#### Scenario: Saved progress label

- **WHEN** `basic-text` has a resume point at chapter index 4, position 120 s, and chapters 1–4 total 1800 s
- **THEN** the bar is at `1920 / total` and the label reads "Chapter 5 of 97 · <formatted total-1920> left"

#### Scenario: Fresh book has no progress

- **WHEN** a book has a resume point at index 0 position 2 s
- **THEN** no bar or label is shown

#### Scenario: Live progress while playing

- **WHEN** `how-and-why` is playing chapter index 2
- **THEN** the label reads "Now playing · Chapter 3 of 39" with no time left

### Requirement: Book page

Each book page (title = book title, "Back" button to `/audiobooks`) SHALL show
the cover at 150 × 150, then, when there is a continue index, a sticky
"Continue listening" (Fortsæt afspilning) header with that chapter row followed
by a sticky "Chapters" (Kapitler) header; then all chapters as rows with title,
duration label, and, for the resume chapter or the playing chapter, a progress
bar with label. The continue index is the playing chapter when this book is
active, else the resume point's chapter when valid.

#### Scenario: Continue row shows the resume chapter

- **WHEN** the book is idle and has a resume point at index 10
- **THEN** the "Continue listening" section shows chapter 11 and the full list follows

#### Scenario: No continue row for a new book

- **WHEN** the book has no resume point and is not playing
- **THEN** the list starts directly with the chapters

### Requirement: Chapter tap

Tapping a chapter row SHALL start that chapter in the media player as a book
playlist (`id` = book id, `type` = book, `title` = book title, tracks = all
chapters in order with `id` = `url`). Tapping the chapter that is already
active toggles play/pause instead. The row icon is a pause icon when that
chapter is playing and a play icon otherwise; rows with progress use the primary
icon colour, others the medium colour.

#### Scenario: Tap starts the chapter

- **WHEN** the user taps chapter 3 of an idle book
- **THEN** the player starts the book playlist at index 2

#### Scenario: Tap on the playing chapter pauses

- **WHEN** chapter 3 is playing and the user taps its row
- **THEN** playback pauses and the icon becomes a play icon

### Requirement: Chapter progress label

The resume chapter SHALL show a bar `position / duration` and the label
"Continue from <position>[ · <duration - position> left]" when the position is
at least 5 s and less than 99.5 % of the duration; the playing chapter shows
`position / duration` and "Now playing · <position> / <duration>". Times use
`m:ss` or `h:mm:ss`.

#### Scenario: Resume label

- **WHEN** the resume point is position 95 s in a chapter of 490 s
- **THEN** the label reads "Continue from 1:35 · 6:35 left"

#### Scenario: Almost finished chapter shows nothing

- **WHEN** the resume position is 99.6 % of the duration
- **THEN** no bar or label is shown for that chapter

### Requirement: Back behaviour

The system back button on a book page SHALL navigate to `/audiobooks`; the
"Back" header button does the same.

#### Scenario: System back returns to the list

- **WHEN** the user presses back on `/step-working-guides`
- **THEN** `/audiobooks` is shown

### Requirement: Refresh on return

Progress on both the list and the book pages SHALL refresh when the page is
shown again and whenever the player state changes (including going idle).

#### Scenario: Progress updates after listening

- **WHEN** the user listens to 10 minutes of chapter 1 and returns to the Audiobooks list
- **THEN** the book row shows a progress bar and "Chapter 1 of 97 · … left"

## Intentional deltas from the legacy app

- The three legacy book pages were copies of one component differing only in ids; one book page parameterised by book id.
- The book duration labels were hard-coded in the page; they remain constants but are asserted equal to the sum of chapter durations by a unit test.
- Legacy loaded book JSON over HTTP from `assets/data`; bundled assets are read through an adapter.
- Legacy titles for books came from the translation keys `BASIC_TEXT`, `HOW_AND_WHY`, `STEP_WORKING_GUIDES`; kept as ARB keys.
