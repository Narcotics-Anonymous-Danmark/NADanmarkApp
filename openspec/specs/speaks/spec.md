# Speaks Specification

## Purpose

Speaks lists recorded NA talks from the nadanmark.dk feed, normalises its
hand-maintained data into searchable entries grouped by convention, and plays
them through the global media player with resume support.

> Source: App/src/app/providers/audio.service.ts, App/src/app/pages/speaks/speaks.catalog.ts, App/src/app/pages/speaks/speaks.page.{ts,html} (legacy)

## Requirements

### Requirement: Feed

The app SHALL fetch two feeds from `<NA_API_BASE_URL>/wp-json/wp/v2/speaks`
with the header `Authorization: Basic <base64(NA_API_BASIC_AUTH)>`:
`?excerpt[]=NA-SPEAKS-DK` tagged language `da` and `?excerpt[]=NA-SPEAKS-EN`
tagged language `en`. Each response is an array of groups `{title, speaks:
[{name, location, year, audioUrl}]}`. The two results are concatenated (DK
first). If one feed fails its result is empty; if both fail the load fails. The
result is cached in memory for the session; pull-to-refresh and "Try again"
force a reload.

#### Scenario: One feed failing still loads

- **WHEN** the EN feed returns an error and the DK feed returns 3 groups
- **THEN** the catalog contains the 3 Danish groups and no error is shown

#### Scenario: Both feeds failing is an error

- **WHEN** both requests fail and nothing is cached
- **THEN** the page shows "Could not load the speaks" (Kunne ikke hente speaks), "Check your internet connection and try again." and a "Try again" (Prøv igen) button

### Requirement: Text folding

`foldText(value)` SHALL lower-case the text, replace `æ` → `ae`, `ø` → `o`,
`å` → `a`, strip combining diacritics (NFD, U+0300–U+036F), collapse runs of
whitespace to one space and trim. `tidy(value)` SHALL collapse whitespace,
strip leading `[\s.,;:/-]+`, strip trailing `[\s.,;:]+` and trim.

#### Scenario: Folding Danish letters

- **WHEN** `foldText("  Åbnings-Speak  København ")` is computed
- **THEN** the result is `abnings-speak kobenhavn`

#### Scenario: Tidy strips stray punctuation

- **WHEN** `tidy(".Vilborg trin 10-11-12.")` is computed
- **THEN** the result is `Vilborg trin 10-11-12`

### Requirement: Convention parsing

From a group title the app SHALL strip a trailing "udenlandske speak(s)"
(case-insensitive, with optional leading spaces/dashes), split on the first
" - " (a dash with a space on at least one side), take the left part as the
convention base (default "Speaks") and the right part as the city. The
convention key is `foldText(base)` (default `speaks`); the label is the pretty
form of the base; the city is the pretty form of the right part or absent.
Pretty form: words that are acronyms ending in `kna`/`cna` (possibly joined by
`/`) are upper-cased; all-caps words are lower-cased; other words keep their
case; the first character is upper-cased.

#### Scenario: Convention with city

- **WHEN** the group title is `KOKNA - København`
- **THEN** key = `kokna`, label = `KOKNA`, city = `København`

#### Scenario: Foreign speaks fold into the same convention

- **WHEN** the group titles are `KOKNA - København` and `KOKNA - Udenlandske Speak`
- **THEN** both belong to key `kokna` and the city stays `København`

#### Scenario: Shouty label is sentence-cased

- **WHEN** the group title is `BLANDEDE SPEAK`
- **THEN** the label is `Blandede speak`

### Requirement: Date parsing

From the free-text `year` field (tidied) the app SHALL first try a full date
`d[-/.]m[-/.]yy|yyyy` (two-digit year + 2000; day 1–31, month 1–12) giving
`year`, `dateLabel` `dd-mm-yyyy` and `sortValue = year*10000 + month*100 +
day`; else the first `19xx`/`20xx` in the field, else in the fallback text
(location + file name), giving `year`, no label and `sortValue = year*10000`;
else no date with `sortValue` 0.

#### Scenario: Full date

- **WHEN** the year field is `13-2-22`
- **THEN** year = 2022, dateLabel = `13-02-2022`, sortValue = 20220213

#### Scenario: Year from the file name

- **WHEN** the year field is `?` and the file name is `KOKNA 30 2026 åbningsspeak`
- **THEN** year = 2026 and sortValue = 20260000

#### Scenario: Unknown date

- **WHEN** the year field is `?` and no year appears elsewhere
- **THEN** year is absent and sortValue = 0

### Requirement: Kind detection and speaker

The kind SHALL be detected from the name, the location and the file name (URL
last segment, percent-decoded, extension removed), first match wins on the
folded text: `abning|opening` → opening; `afslutning|closing` → closing;
`hovedspeak|hoved speak|main speak` → main; else none. The speaker is the name
with a leading kind prefix removed
(`^(åbnings?|abnings?|opening|afslutnings?|closing|hoved|main)\s*speak(er)?\b[\s:,.-]*`,
case-insensitive), tidied; empty becomes absent. The avatar initial is the
first letter of the speaker upper-cased. Kind labels are "Opening speak"
(Åbningsspeak), "Main speak" (Hovedspeak), "Closing speak" (Afslutningsspeak).

#### Scenario: Name carries the kind

- **WHEN** the name is `Hovedspeak Sigi`
- **THEN** kind = main, speaker = `Sigi`, initial = `S`

#### Scenario: Kind from the file name only

- **WHEN** the name is empty and the file is `KOKNA 30 2026 åbningsspeak.wav`
- **THEN** kind = opening and the speaker is absent

### Requirement: Title, edition and meta lines

The edition SHALL be the tidied location with convention acronyms upper-cased
(absent when empty or `?`); it is shortened by removing a leading convention label when
the remainder still contains a year. The title SHALL be the first present of
speaker, kind label, short edition, convention label. `meta` joins the short edition and
the time label (dateLabel or year) with " · ", omitting the time when the
edition already contains it. `contextLabel` prefixes the convention label to
`meta` unless `meta` already starts with it. `metaLine` = [kind label (only when
a speaker exists), meta, "English" for `en`] joined by " · ";
`metaLineWithConvention` uses `contextLabel` instead of `meta`.

#### Scenario: Meta with edition and year

- **WHEN** edition is `KOKNA 30`, year 2026 and the speaker is `Sigi` with kind main
- **THEN** title = `Sigi`, meta = `KOKNA 30 · 2026`, metaLine = `Main speak · KOKNA 30 · 2026`

#### Scenario: Edition shortened by convention label

- **WHEN** the convention label is `Konvent-camp Skanderborg` and the location is `Konvent-camp Skanderborg 2015`
- **THEN** the short edition is `2015` and contextLabel = `Konvent-camp Skanderborg · 2015`

### Requirement: Deduplication and catalog

Speaks SHALL be deduplicated by exact `audioUrl` (first occurrence wins; empty
URLs are skipped). The catalog holds the speaks, the conventions in first-seen
order with their counts (conventions with zero speaks removed), and the distinct
years newest first. The `searchText` is `foldText` of title, speaker, kind
label, raw location, group title, convention label, city, year, date label,
`english engelsk udenlandske` (for `en`) or `dansk danish` (for `da`), and the
file name.

#### Scenario: Duplicate URL kept once

- **WHEN** the same `audioUrl` appears in two groups
- **THEN** the catalog contains it once, under the first group

#### Scenario: Language words are searchable

- **WHEN** the user searches `engelsk`
- **THEN** only English-feed speaks match

### Requirement: Search

The search field (placeholder "Search name, convention, city, year …") SHALL
apply 200 ms after the last keystroke. The query is folded and split on spaces;
a speak matches when every term is a substring of its `searchText` (AND).

#### Scenario: All terms must match

- **WHEN** the query is `kokna 2026`
- **THEN** only speaks whose searchText contains both `kokna` and `2026` are listed

### Requirement: Filters and chips

The header SHALL show a "Filters" (Filtre) button with the active filter count,
and, when more than one convention exists, a horizontal chip row "All" + one
chip per convention. The filter panel offers: language chips "All" / "Danish" /
"English"; year chips "All" + the years available under the other active
selections and query (plus any selected year), newest first; sort chips
"Newest" / "Oldest" / "Name"; an "Only started (<n>)" chip when any speak has a
resume point; "Reset" (when anything is active) and "Close". Multiple
conventions, languages and years may be selected (OR within a group, AND across
groups).

#### Scenario: Convention chip filters the list

- **WHEN** the user taps the `KOKNA` chip
- **THEN** only KOKNA speaks are listed and the filter count is 1

#### Scenario: Year options follow other filters

- **WHEN** language `en` is selected
- **THEN** the year chips show only years present among English speaks

#### Scenario: Reset clears everything

- **WHEN** filters and a query are active and the user taps "Reset"
- **THEN** the query, all selections, "Only started" and the sort are back to defaults (sort = Newest)

### Requirement: Sorting and grouping

Results SHALL be ordered by convention (catalog order) first, then within a
convention: for "Name" by title (Danish collation); for "Newest" by `sortValue`
descending; for "Oldest" ascending; speaks with `sortValue` 0 sort last in both
date modes; ties break by title. The visible list is split into sticky
convention sections "<label>[ · <city>]". A count line "<n> speaks" is shown
above the list; the empty state reads "No speaks found" with "Try another
search word, or reset the filters." and a "Reset" button when filters are
active.

#### Scenario: Newest first within a convention

- **WHEN** KOKNA has speaks with sortValue 20260000, 20250000 and 0
- **THEN** they are listed in that order under the KOKNA header

#### Scenario: Empty result state

- **WHEN** the query matches nothing
- **THEN** "No speaks found" is shown with the reset button

### Requirement: Paging

The list SHALL show the first 40 results and load 40 more on infinite scroll
until all are shown. Any filter or query change resets to the first page and
scrolls to the top.

#### Scenario: Second page

- **WHEN** 100 speaks match and the user scrolls to the end
- **THEN** 80 are shown, then 100

### Requirement: Continue listening

Above the results the page SHALL show a "Continue listening" (Fortsæt
afspilning) section with at most 10 speaks that have a resume point producing a
progress label, ordered by `updatedAt` descending with the currently active
speak first. Rows there use `metaLineWithConvention`. Swiping a row reveals
"Remove from list" (Fjern fra listen), which clears the speak's resume point.

#### Scenario: Most recent first, capped at ten

- **WHEN** 12 speaks have resume points
- **THEN** the 10 most recently updated are shown, newest first

#### Scenario: Swipe forgets the speak

- **WHEN** the user swipes a continue row and taps "Remove from list"
- **THEN** its resume point is removed and the row disappears

### Requirement: Rows and playback

Each row SHALL show a play/pause icon (pause when active and playing, spinner
while loading), the title and the meta line, plus a progress bar and label when
started. Tapping plays the speak as a playlist with `id` = `audioUrl`, `type` =
speak, `title` = the raw group title, one track titled "<title>[ · <kind
label>][ · <meta>]" (kind only when a speaker exists). Tapping the active row
toggles play/pause. Started rows use the light row colour and the primary icon
colour.

#### Scenario: Tap plays the speak

- **WHEN** the user taps an idle speak row
- **THEN** the player starts a speak playlist with that URL and the docked player appears

#### Scenario: Progress refreshes on pause

- **WHEN** the active speak is paused
- **THEN** its row shows "Continue from <position> · <left> left"

## Intentional deltas from the legacy app

- The legacy `environment.speakersApiUrl` (`nadanmark.dk/api/speaks`) was unused; the WordPress endpoint above is the only source.
- Kind labels were injected as translated strings into the catalog builder; the rewrite keeps the kind as a value and localises at render time, so the catalog is not rebuilt on language change.
- Legacy rebuilt the catalog on every language change; not needed.
- Loading placeholders (8 skeleton rows) are kept as a widget but not part of the contract.
