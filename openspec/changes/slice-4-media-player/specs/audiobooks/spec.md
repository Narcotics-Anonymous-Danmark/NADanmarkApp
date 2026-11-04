# Spec Delta

## MODIFIED Requirements

### Requirement: The three books

The app SHALL bundle three books, each as a JSON asset with `bookTitle`,
`bookEdition`, `bookAuthor` and `chapters[]` of `{title, url, duration}`
(`duration` as `m:ss` or `h:mm:ss`). The JSON files are the legacy files,
unchanged, in `adapter_assets`; the covers are the legacy PNGs in
`feature_audiobooks`:

| Id | Route | Title (Danish) | Chapters | Total duration | Cover |
|---|---|---|---|---|---|
| `basic-text` | `/basic-text` | Basic Text (Basis Tekst) | 97 | 13:53:58 | `covers/basic-text.png` |
| `how-and-why` | `/how-and-why` | It Works: How and Why (Det Virker: Hvordan og Hvorfor) | 39 | 06:11:37 | `covers/how-and-why.png` |
| `step-working-guides` | `/step-working-guides` | The NA Step Working Guides (Vejledninger i Trinarbejde) | 13 | 05:03:49 | `covers/step-working-guides.png` |

Chapter audio URLs are absolute `https://www.nadanmark.dk/wp-content/uploads/…`
MP3 files. Each total duration equals the sum of the book's chapter
durations.

#### Scenario: Chapter counts

- **WHEN** the three book assets are loaded
- **THEN** they contain 97, 39 and 13 chapters respectively

#### Scenario: Totals match the chapters

- **WHEN** the chapter durations of each book are added up
- **THEN** they equal 13:53:58, 06:11:37 and 05:03:49

### Requirement: Book page

Each book page (title = book title in the app language, a Back button to
`/audiobooks`) SHALL show the cover at 150 × 150, then, when there is a
continue index, a "Continue listening" (Fortsæt afspilning) header with that
chapter row followed by a "Chapters" (Kapitler) header; then all chapters as
rows with title, duration label, and, for the resume chapter or the playing
chapter, a progress bar with label. The continue index is the playing chapter
when this book is active, else the resume point's chapter when valid. When
the book data cannot be read the page shows "The book could not be loaded."
(Bogen kunne ikke indlæses.).

#### Scenario: Continue row shows the resume chapter

- **WHEN** the book is idle and has a resume point at index 10
- **THEN** the "Continue listening" section shows chapter 11 and the full list follows

#### Scenario: No continue row for a new book

- **WHEN** the book has no resume point and is not playing
- **THEN** the list starts directly with the chapters

#### Scenario: Book that cannot be read

- **WHEN** the book asset cannot be read
- **THEN** the page shows "The book could not be loaded."

### Requirement: Back behaviour

The system back button on a book page SHALL navigate to `/audiobooks`; the
Back header button does the same. Playback continues.

#### Scenario: System back returns to the list

- **WHEN** the user presses back on `/step-working-guides`
- **THEN** `/audiobooks` is shown

#### Scenario: Header back keeps playing

- **WHEN** a chapter of How and Why plays and the user taps Back
- **THEN** `/audiobooks` is shown and the docked player still plays

### Requirement: Refresh on return

Progress on both the list and the book pages SHALL always reflect the shared
resume-point state, which the player updates on every save and clear, and
the live player state while a book is active (including going idle).

#### Scenario: Progress updates after listening

- **WHEN** the user listens to 10 minutes of chapter 1 and returns to the Audiobooks list
- **THEN** the book row shows a progress bar and "Chapter 1 of 97 · … left"

#### Scenario: Finishing a book removes its progress

- **WHEN** the last chapter of a book ends
- **THEN** the book row shows no progress
