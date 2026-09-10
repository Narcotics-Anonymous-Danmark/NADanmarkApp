# Meetings Search Specification

## Purpose

Finding NA meetings is the app's core job. This capability covers the BMLT data
access, the full meeting list grouped by municipality, the "Meetings nearby"
radius search, the shared meeting list component (day grouping, sorting,
filters), the meeting card, meeting format resolution and the meeting details
modal. The map page is specified separately in `meetings-map`.

> Source: App/src/app/providers/meeting-list.service.ts, App/src/app/providers/meeting-formats.service.ts, App/src/app/components/meeting-list/*, App/src/app/components/meeting-card/*, App/src/app/components/meeting-formats/*, App/src/app/pages/listfull/*, App/src/app/pages/location-search/*, App/src/app/pages/modal/*, App/src/app/pipes/tidy-delimiter.pipe.ts (legacy)

## Requirements

### Requirement: BMLT endpoints

The app SHALL read meetings from two BMLT root servers configured through
`BMLT_DENMARK_BASE_URL` (default
`https://www.nadanmark.dk/main_server/client_interface/json/`) and
`BMLT_TOMATO_BASE_URL` (default
`https://tomato.bmltenabled.org/main_server/client_interface/json/`), using
exactly these queries:

| Use | Base | Query |
|---|---|---|
| All meetings | Denmark | `?switcher=GetSearchResults&sort_keys=weekday_tinyint,start_time` |
| Municipalities | Denmark | `?switcher=GetSearchResults&data_field_key=location_municipality&sort_keys=location_municipality` |
| Formats | Denmark | `?switcher=GetFormats` and `?switcher=GetFormats&lang_enum=dk` |
| Nearby (radius) | Tomato | `?switcher=GetSearchResults&geo_width_km=<km>&long_val=<lng>&lat_val=<lat>&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic` |
| Map pins | Tomato | `?switcher=GetSearchResults&data_field_key=longitude,latitude,id_bigint&geo_width_km=<km>&long_val=<lng>&lat_val=<lat>&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic` |
| Meetings by id | Tomato | `?switcher=GetSearchResults&meeting_ids[]=<id>[&meeting_ids[]=<id>…]` |

A response that is an empty JSON object `{}` (BMLT's "no results") SHALL be
treated as an empty list. `callingApp` SHALL be `bmlt_search_3_ionic` until the
BMLT admins are told otherwise.

#### Scenario: Empty object means no meetings

- **WHEN** the radius query returns `{}`
- **THEN** the result is an empty meeting list and no error is shown

#### Scenario: Radius query carries the exact parameters

- **WHEN** a nearby search runs for lat 55.476224, lng 8.4606976, 15 km
- **THEN** the request is `<tomato>?switcher=GetSearchResults&geo_width_km=15&long_val=8.4606976&lat_val=55.476224&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic`

### Requirement: Full meeting list by municipality

The Meetings page (`/listfull`, title "Meetings" (Mødeliste)) SHALL load the
municipalities and show one row per distinct municipality with a play chevron.
Municipalities that are blank, "Online møde", "Viborg online" or "Viborg." SHALL
be shown as one entry "Online", which sorts last; all others keep the server
order. Tapping a municipality loads all meetings and shows those whose
normalised municipality equals the tapped one, in the shared meeting list, with
the header title set to the municipality name and a "Back" button that returns
to the municipality list. The loading bar shows "Finding meetings…" (Finder
møder …) while either request runs.

#### Scenario: Municipalities are unique and Online is last

- **WHEN** the municipality query returns `Aarhus, Aarhus, København, "", Online møde, Viborg.`
- **THEN** the rows are `Aarhus, København, Online`

#### Scenario: Municipality meetings are filtered

- **WHEN** the user taps "Aarhus"
- **THEN** only meetings with `location_municipality == "Aarhus"` are listed
- **AND** the header reads "Aarhus" with a "Back" button

#### Scenario: Online groups all blank-like municipalities

- **WHEN** the user taps "Online"
- **THEN** meetings whose municipality is blank, "Online møde", "Viborg online" or "Viborg." are listed

### Requirement: Meetings nearby

The "Meetings nearby" page (`/location-search`) SHALL search the Tomato radius
endpoint around the device position with the radius from the `searchRange`
setting (default 15). A footer holds a "Meetings nearby" button that re-locates
the device and a radius slider 5–50 km (labels "5 km", "50 km") that re-runs the
search 500 ms after the last change without re-locating. Results are shown in
the shared meeting list. When no position could be determined the default
coordinates lat `55.476224`, lng `8.4606976` are used.

#### Scenario: Search uses the default radius setting

- **WHEN** `searchRange` is 20 and the page opens
- **THEN** the first search uses `geo_width_km=20` and the slider shows 20

#### Scenario: Slider re-searches without relocating

- **WHEN** the user moves the slider to 30
- **THEN** a new search runs 500 ms after the last slider change with the same coordinates and `geo_width_km=30`
- **AND** no new location request is made

#### Scenario: Fallback to default coordinates

- **WHEN** location fails or times out
- **THEN** the search runs for lat 55.476224, lng 8.4606976

### Requirement: Location acquisition and timeouts

Locating SHALL show "Locating…" (Finder position …) in the loading bar. The
timeout is 10 s when location permission is already granted and 45 s when it is
not (to allow the permission prompt). On timeout the search runs with the
current best coordinates (default if none); if a position arrives after the
timeout the search runs again with the real position.

#### Scenario: Permission granted times out after 10 seconds

- **WHEN** permission is granted and no position arrives for 10 s
- **THEN** the loading bar hides and the search runs with the default coordinates

#### Scenario: Late position triggers a second search

- **WHEN** the position arrives 12 s after a 10 s timeout
- **THEN** a second search runs with the real coordinates and replaces the list

#### Scenario: Without permission the timeout is 45 seconds

- **WHEN** permission is not granted and the user does not answer the prompt
- **THEN** the search runs with default coordinates after 45 s

### Requirement: Weekday grouping and ordering

The shared meeting list SHALL group meetings by `weekday_tinyint` (1 = Sunday …
7 = Saturday), one collapsible section per day with the header "<Weekday>
(<count>)". Sections are ordered Monday…Sunday when `firstday` is `mo` and
Sunday…Saturday when it is `su`. Within a day meetings are sorted by start
time. The header of today's section uses the secondary colour, all others the
primary colour. All sections start collapsed; tapping a header expands it and
collapses any other open section.

#### Scenario: Monday first moves Sunday to the end

- **WHEN** `firstday` is `mo` and there are meetings on Sunday and Monday
- **THEN** the Monday section is listed before the Sunday section

#### Scenario: Today's header is highlighted

- **WHEN** today is Wednesday
- **THEN** the "Wednesday (n)" header uses the secondary colour and the others the primary colour

#### Scenario: One section open at a time

- **WHEN** Monday is expanded and the user taps Tuesday
- **THEN** Tuesday is expanded and Monday is collapsed

### Requirement: Day and hour filters

Above the sections the list SHALL offer a day selector with "All days"
(Alle dage) plus the seven weekdays in `firstday` order, and a dual-knob hour
range 0–23 (step 1). A meeting passes when its weekday matches the selected day
(or "All days") and its start hour is between the lower and upper knob
inclusive. Filtering re-computes the per-day counts. The hour filter applies
350 ms after the last change.

#### Scenario: Day filter keeps one section

- **WHEN** the user selects "Friday"
- **THEN** only the Friday section is shown with its count

#### Scenario: Hour range filters by start hour

- **WHEN** the range is 18–20
- **THEN** meetings starting 18:00–20:59 are listed and a 17:30 meeting is not

### Requirement: Meeting times

Start time SHALL be shown as `HH:mm` from `start_time`; end time SHALL be
`start_time + duration_time` formatted `HH:mm`. Times are shown as given by the
server, in the meeting's own local time, without time-zone conversion.

#### Scenario: End time is start plus duration

- **WHEN** `start_time` is `19:00:00` and `duration_time` is `01:30:00`
- **THEN** the card badge reads "<Weekday> 19:00 - 20:30"

### Requirement: Meeting card

The meeting card SHALL show: a badge "<Weekday> <start> - <end>"; a red
"Temporarily closed" (Midlertidigt lukket) chip when the TC rule applies; the
meeting name as heading; the format chips; then, each on its own line when
present: `location_text`, `location_street`, `location_city_subsection`,
`location_neighborhood`, `location_municipality`, `location_sub_province`,
`location_province`, `location_code_1`, `location_info`, `comments` (with a note
icon), `virtual_meeting_additional_info`, `contact_phone_1`, `contact_email_1`,
"Train: <train_lines>", "Bus: <bus_lines>". The literal prefixes
`Bus Lines#@-@#` and `Train Lines#@-@#` are stripped from the transit fields.

#### Scenario: Only present fields are rendered

- **WHEN** a meeting has `location_street` and `location_municipality` but no other location fields
- **THEN** exactly those two location lines are shown

#### Scenario: Transit prefix is stripped

- **WHEN** `bus_lines` is `Bus Lines#@-@#2A, 5C`
- **THEN** the line reads "Bus: 2A, 5C"

### Requirement: Temporarily closed rule

A meeting SHALL be marked temporarily closed when its `formats` contain the key
`TC` (case-insensitive) and it has no `virtual_meeting_link`. A hybrid meeting
is one whose `formats` contain `HY` (case-insensitive).

#### Scenario: TC without virtual link is closed

- **WHEN** `formats` is `O,TC` and `virtual_meeting_link` is empty
- **THEN** the "Temporarily closed" chip is shown

#### Scenario: TC with a virtual link is not closed

- **WHEN** `formats` is `O,TC` and `virtual_meeting_link` is a URL
- **THEN** no chip is shown

### Requirement: Meeting card actions

The card SHALL show: a "Directions" (Kørselsvejledning) button opening
`https://www.google.com/maps/search/?api=1&query=<latitude>,<longitude>` when
the meeting has no `virtual_meeting_link` or is hybrid; a "Virtual link" (Link
til netmøde) button opening `virtual_meeting_link` when present; a "Phone
meeting dial-in" (Telefonmøde – opkaldsnummer) button dialling
`tel:<phone_meeting_number>` when both `virtual_meeting_link` and
`phone_meeting_number` are present. All open in the system handler.

#### Scenario: In-person meeting shows directions only

- **WHEN** a meeting has coordinates and no virtual link
- **THEN** only "Directions" is shown and tapping it opens the Google Maps search URL

#### Scenario: Hybrid meeting shows directions and virtual link

- **WHEN** `formats` contain `HY` and `virtual_meeting_link` is set
- **THEN** both "Directions" and "Virtual link" are shown

#### Scenario: Virtual meeting with phone number

- **WHEN** `virtual_meeting_link` and `phone_meeting_number` are set and the meeting is not hybrid
- **THEN** "Virtual link" and "Phone meeting dial-in" are shown and "Directions" is not

### Requirement: Format definitions and cache

Format definitions SHALL be fetched from both GetFormats queries (default
language and `lang_enum=dk`), concatenated, and cached under the key
`meeting_formats_v1` as `{fetchedAt: <epoch ms>, formats: [...]}` for 7 days
(`7 * 24 * 60 * 60 * 1000` ms). On fetch failure the stale cache is used if
present, else an empty list, and a retry is allowed after 60 s. The cache is
never written empty.

#### Scenario: Fresh cache avoids the network

- **WHEN** the cache was written 3 days ago
- **THEN** no GetFormats request is made

#### Scenario: Stale cache used when offline

- **WHEN** the cache is 8 days old and the network fails
- **THEN** the cached formats are used

#### Scenario: Failure allows retry after a minute

- **WHEN** the fetch fails with no cache
- **THEN** meetings show raw keys as chips and a new fetch is attempted on the first request after 60 s

### Requirement: Format category and display language

Each format id SHALL become one definition using the row in the display
language (`dk` when the app language is `da`, else `en`), falling back to the
`en` row, then to the first row. `format_type_enum` maps to a category:
`ALERT` → alert, `LANG` → language, prefixes `FC3`, `O`, `C` → audience, prefix
`FC2` → facility, anything else → content. Chip colours by category: alert
danger, language tertiary, audience primary, facility dark, content dark. The
index is rebuilt when the language changes.

#### Scenario: Danish names in Danish

- **WHEN** the app language is `da` and format id 17 has rows in `dk` and `en`
- **THEN** the chip shows the `dk` `name_string`

#### Scenario: Category mapping

- **WHEN** `format_type_enum` is `FC2`
- **THEN** the category is facility and the chip colour dark

### Requirement: Resolving a meeting's formats

For a meeting from the Danish root (`root_server_uri` contains `nadanmark.dk`)
each key in `formats` SHALL be resolved by shared id (`format_shared_id_list`
at the same position, only when the id count equals the key count and
`root_server_id` is absent), then by exact key, then by lower-cased key when
that lower-cased key is unambiguous. For any other root server keys resolve
through the English key index only. Unresolved keys SHALL become a content
format whose name is the key. Duplicates by key are dropped; the result is
sorted by category order (alert, language, audience, facility, content) then by
name with Danish collation. Tapping the chips opens the formats popover.

#### Scenario: Danish meeting resolves by shared id

- **WHEN** `formats` is `O,TC`, `format_shared_id_list` is `17,54` and the meeting is from `nadanmark.dk`
- **THEN** the chips are the definitions with ids 17 and 54 sorted alert first

#### Scenario: Unknown key is shown raw

- **WHEN** `formats` contains `XYZ` that no index knows
- **THEN** a dark chip labelled "XYZ" is shown

#### Scenario: Ambiguous lower-case key is not guessed

- **WHEN** two definitions have keys `Se` and `SE`
- **THEN** the key `se` resolves to neither by the lower-case index

### Requirement: Formats popover

The popover SHALL be titled "Meeting formats" (Mødeformater) with a close
button, show the meeting name in bold, and list each format as a coloured
badge with its key, the name and the description when present.

#### Scenario: Popover lists formats with descriptions

- **WHEN** the user taps the chips of a meeting with formats `O` and `TC`
- **THEN** the popover shows two rows with badges "O" and "TC", their names and descriptions

### Requirement: Meeting details modal

The meeting details modal (title "Meeting details" (Mødedetaljer), "Close"
button) SHALL fetch the meetings by id from Tomato and render one meeting card
per result. It is opened from the map (one or several co-located ids).

#### Scenario: Modal shows all co-located meetings

- **WHEN** the modal opens for ids `123` and `456`
- **THEN** two meeting cards are shown in the returned order

#### Scenario: Close dismisses the modal

- **WHEN** the user taps "Close"
- **THEN** the modal is dismissed and the map is unchanged

### Requirement: Loading states

Each network call SHALL be reflected in the global loading bar with the texts
"Finding meetings…" (Finder møder …) or "Locating…" (Finder position …). A page
never shows two overlapping loading bars.

#### Scenario: Loader text while searching

- **WHEN** a nearby search is in flight
- **THEN** the loading bar is visible with the status "Finding meetings…"

## Intentional deltas from the legacy app

- The legacy municipality list normalised "Online møde", "Viborg online" and "Viborg." to "Online" but then filtered meetings with `location_municipality == ""` only, so those meetings appeared nowhere. Filtering uses the same normalisation.
- The legacy "Meetings nearby" fallback radius was 25 while Settings defaulted to 15. One default: 15.
- The legacy `meetingType = 'virt'` code path (virtual-na.org meetings, time-zone conversion to the device zone with a "(zone)" suffix, "Virtual link" from `comments`) was never reachable from any page and is not ported. The `GetServiceBodies` and virtual-NA endpoints are not ported.
- The legacy list sorted meetings within a day by the display string `HH:mm`; the rewrite sorts by start time value, which gives the same order.
- The legacy hour slider showed "HH:mm (h:mm a)" preview text that was commented out in the template; not ported.
- The legacy `isTempClosed` in the modal page ignored the virtual link; the card rule (with the virtual-link exception) is the only rule.
- The loading texts are localised, including "Loading events…" which was hard-coded English.
