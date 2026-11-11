# Spec Delta

## MODIFIED Requirements

### Requirement: Feed

The app SHALL fetch two feeds from `<NA_API_BASE_URL>/wp-json/wp/v2/speaks`
with the header `Authorization: Basic <base64(NA_API_BASIC_AUTH)>` (left out
when the setting is empty): `?excerpt[]=NA-SPEAKS-DK` tagged language `da` and
`?excerpt[]=NA-SPEAKS-EN` tagged language `en`. Each response is an array of
groups `{title, speaks: [{name, location, year, audioUrl}]}`. The two results
are concatenated (DK first). If one feed fails its result is empty; if both
fail the load fails. The result is cached in memory for the session;
pull-to-refresh and "Try again" force a reload. A reload that fails while a
catalogue is shown keeps that catalogue.

#### Scenario: One feed failing still loads

- **WHEN** the EN feed returns an error and the DK feed returns 3 groups
- **THEN** the catalog contains the 3 Danish groups and no error is shown

#### Scenario: Both feeds failing is an error

- **WHEN** both requests fail and nothing is cached
- **THEN** the page shows "Could not load the speaks" (Kunne ikke hente speaks), "Check your internet connection and try again." and a "Try again" (Prøv igen) button

#### Scenario: Try again reloads

- **WHEN** both requests failed, the server recovers and the user taps "Try again"
- **THEN** the speaks are listed

#### Scenario: Failed refresh keeps the list

- **WHEN** speaks are listed, both requests start failing and the user pulls to refresh
- **THEN** the same speaks are still listed and no error is shown

### Requirement: Kind detection and speaker

The kind SHALL be detected from the name, the location and the file name (URL
last segment, percent-decoded, extension removed), first match wins on the
folded text: `abning|opening` → opening; `afslutning|closing` → closing;
`hovedspeak|hoved speak|main speak` → main; else none. The speaker is the name
with a leading kind prefix removed
(`^(åbnings?|abnings?|opening|afslutnings?|closing|hoved|main)\s*speak(er)?\b[\s:,.-]*`,
case-insensitive), tidied; empty becomes absent. Kind labels are "Opening
speak" (Åbningsspeak), "Main speak" (Hovedspeak), "Closing speak"
(Afslutningsspeak), rendered in the app language.

#### Scenario: Name carries the kind

- **WHEN** the name is `Hovedspeak Sigi`
- **THEN** kind = main and speaker = `Sigi`

#### Scenario: Kind from the file name only

- **WHEN** the name is empty and the file is `KOKNA 30 2026 åbningsspeak.wav`
- **THEN** kind = opening and the speaker is absent

### Requirement: Deduplication and catalog

Speaks SHALL be deduplicated by exact `audioUrl` (first occurrence wins; empty
or invalid URLs are skipped). The catalog holds the speaks, the conventions in
first-seen order with their counts and the first city seen (conventions with
zero speaks removed), and the distinct years newest first. The `searchText` is
`foldText` of title, speaker, the kind labels of both app languages, raw
location, group title, convention label, city, year, date label,
`english engelsk udenlandske` (for `en`) or `dansk danish` (for `da`), and the
file name.

#### Scenario: Duplicate URL kept once

- **WHEN** the same `audioUrl` appears in two groups
- **THEN** the catalog contains it once, under the first group

#### Scenario: Language words are searchable

- **WHEN** the user searches `engelsk`
- **THEN** only English-feed speaks match

#### Scenario: Kind words in both languages are searchable

- **WHEN** the app language is English and the user searches `hovedspeak`
- **THEN** the main speaks are listed

### Requirement: Filters and chips

Next to the search field the page SHALL show a "Filters" (Filtre) button that
shows the active filter count instead of its label when filters are active,
and, when more than one convention exists, a horizontal chip row "All" + one
chip per convention. The filter panel offers: language chips "All" /
"Danish" / "English"; year chips "All" + the years available under the other
active selections and query (plus any selected year), newest first; sort chips
"Newest" / "Oldest" / "Name"; an "Only started (<n>)" chip when any speak has
a resume point or "Only started" is on; "Reset" (when anything is active) and
"Close". Multiple conventions, languages and years may be selected (OR within
a group, AND across groups).

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
convention: for "Name" by folded title, then title; for "Newest" by
`sortValue` descending; for "Oldest" ascending; speaks with `sortValue` 0 sort
last in both date modes; ties break by folded title, then title. The visible
list is split into sticky convention sections "<label>[ · <city>]" using the
convention's city. A count line "<n> speaks" is shown above the list; the
empty state reads "No speaks found" with "Try another search word, or reset
the filters." and a "Reset" button when filters are active.

#### Scenario: Newest first within a convention

- **WHEN** KOKNA has speaks with sortValue 20260000, 20250000 and 0
- **THEN** they are listed in that order under the KOKNA header

#### Scenario: Name sort folds Danish letters

- **WHEN** the sort is "Name" and a convention has speakers `Åse`, `Bo` and `Anders`
- **THEN** they are listed as `Anders`, `Åse`, `Bo`

#### Scenario: Empty result state

- **WHEN** the query matches nothing
- **THEN** "No speaks found" is shown with the reset button

### Requirement: Rows and playback

Each row SHALL show a play/pause icon (pause when active and playing, spinner
while loading), the title and the meta line, plus a progress bar and label when
started: the active speak shows "Now playing · <position>[ / <length>]",
any other speak with a resume point "Continue from <position>[ · <left>
left]". Tapping plays the speak as a playlist with `id` = `audioUrl`, `type` =
speak, `title` = the tidied group title, the NA logo as cover, one track titled
"<title>[ · <kind label>][ · <meta>]" (kind only when a speaker exists).
Tapping the active row toggles play/pause. Started rows use the light row
colour and the primary icon colour.

#### Scenario: Tap plays the speak

- **WHEN** the user taps an idle speak row
- **THEN** the player starts a speak playlist with that URL and the docked player appears

#### Scenario: Tapping the active row pauses

- **WHEN** a speak is playing and the user taps its row
- **THEN** the player is paused and the row shows the play icon

#### Scenario: A speak shows its length and can be scrubbed

- **WHEN** a speak of 10:00 is playing, its length reported by the audio engine while loading
- **THEN** the docked player shows 10:00 as the length, and dragging the scrubber to the middle continues at 5:00

#### Scenario: Active row shows live progress

- **WHEN** a speak of 10:00 is playing at 2:00
- **THEN** its row shows "Now playing · 2:00 / 10:00"

#### Scenario: Progress refreshes when the player closes

- **WHEN** a speak of 10:00 was played to 4:10 and the player is closed
- **THEN** its row shows "Continue from 4:10 · 5:50 left"

## REMOVED Requirements

None.

## Workflow follow-up

On archive, add to "Intentional deltas from the legacy app" in
`openspec/specs/speaks/spec.md`:
- the avatar initial is not computed, since the legacy page never showed it;
- "Name" sorting compares folded titles instead of Danish collation;
- section headers show the convention's city, not the first visible speak's;
- the Filters button sits next to the search field;
- a failed refresh keeps the catalogue shown;
- speaks use the NA logo as their lock-screen cover.
