# Spec Delta

## MODIFIED Requirements

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
| Formats | Denmark | `?switcher=GetFormats&lang_enum=da` and `?switcher=GetFormats&lang_enum=en` |
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

#### Scenario: Formats are fetched in both languages

- **WHEN** the format definitions are fetched
- **THEN** the requests are `<denmark>?switcher=GetFormats&lang_enum=da` and `<denmark>?switcher=GetFormats&lang_enum=en`

### Requirement: Format category and display language

Each format id SHALL become one definition using the row in the display
language (`da` when the app language is `da`, else `en`), falling back to the
`en` row, then to the first row. `format_type_enum` maps to a category:
`ALERT` → alert, `LANG` → language, prefixes `FC3`, `O`, `C` → audience, prefix
`FC2` → facility, anything else → content. Chip colours by category: alert
danger, language tertiary, audience primary, facility dark, content dark. The
index is rebuilt when the language changes.

#### Scenario: Danish names in Danish

- **WHEN** the app language is `da` and format id 17 has rows in `da` and `en`
- **THEN** the chip shows the `da` `name_string`

#### Scenario: English names in English

- **WHEN** the app language is `en` and format id 17 has rows in `da` ("Åben Møde") and `en` ("Open")
- **THEN** the chip shows "Open"

#### Scenario: Category mapping

- **WHEN** `format_type_enum` is `FC2`
- **THEN** the category is facility and the chip colour dark

### Requirement: Full meeting list by municipality

The Meetings page (`/listfull`, title "Meetings" (Mødeliste)) SHALL load the
municipalities and show one row per distinct municipality with a play chevron.
Municipalities that are blank, "Online møde", "Viborg online" or "Viborg." SHALL
be shown as one entry "Online", which sorts last; all others keep the server
order. The "Online" label is localised. Tapping a municipality SHALL open the
sub-page `/listfull/<municipality>`. The sub-page loads all meetings and shows
those whose normalised municipality equals the tapped one, in the shared
meeting list. Its header title is the municipality name, and a "Back" button
returns to the municipality list. The sub-page SHALL NOT show meetings of a
previously opened municipality while it loads. The loading bar shows "Finding
meetings…" (Finder møder …) while either request runs. When the municipality
query returns no rows the page SHALL show "Nothing found" (Intet fundet). When
either request fails, the page SHALL show "The meetings could not be loaded"
(Møderne kunne ikke hentes) with a "Try again" (Prøv igen) button that repeats
the failed request, and the loading bar SHALL be hidden.

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

#### Scenario: Back returns to the municipality list

- **WHEN** the user is on the "Aarhus" meetings and taps "Back"
- **THEN** the municipality list is shown with the title "Meetings"

#### Scenario: No municipalities

- **WHEN** the municipality query returns `{}`
- **THEN** the page shows "Nothing found" and the loading bar is hidden

#### Scenario: Failed request can be retried

- **WHEN** the municipality query fails and the user taps "Try again" after the server recovers
- **THEN** the error is replaced by the municipality rows and the loading bar is hidden

#### Scenario: Previous municipality is not shown while loading

- **WHEN** the user has seen the "Aarhus" meetings, goes back and taps "København" while the meetings request is still pending
- **THEN** no "Aarhus" meeting is shown

### Requirement: Meeting card

The meeting card SHALL show: a badge "<Weekday> <start> - <end>"; a red
"Temporarily closed" (Midlertidigt lukket) chip when the TC rule applies; the
meeting name as heading; the format chips; then, each on its own line when
present: `location_text`, `location_street`, `location_city_subsection`,
`location_neighborhood`, `location_municipality`, `location_sub_province`,
`location_province`, `location_postal_code_1`, `location_info`, `comments` (with
a note icon), `virtual_meeting_additional_info`, `contact_phone_1`,
`contact_email_1`, "Train: <train_lines>", "Bus: <bus_lines>". The literal
prefixes `Bus Lines#@-@#` and `Train Lines#@-@#` are stripped from the transit
fields, case-insensitively and at every occurrence. Values are trimmed, and a
value that is blank after trimming counts as absent.

#### Scenario: Only present fields are rendered

- **WHEN** a meeting has `location_street` and `location_municipality` but no other location fields
- **THEN** exactly those two location lines are shown

#### Scenario: Transit prefix is stripped

- **WHEN** `bus_lines` is `Bus Lines#@-@#2A, 5C`
- **THEN** the line reads "Bus: 2A, 5C"

#### Scenario: Postal code is shown

- **WHEN** a meeting has `location_postal_code_1` `8000`
- **THEN** a location line reads "8000"

### Requirement: Temporarily closed rule

A meeting SHALL be marked temporarily closed when its `formats` list contains
the key `TC` (case-insensitive, compared as a whole comma-separated key after
trimming) and it has no `virtual_meeting_link`. A hybrid meeting is one whose
`formats` list contains the key `HY` under the same comparison.

#### Scenario: TC without virtual link is closed

- **WHEN** `formats` is `O,TC` and `virtual_meeting_link` is empty
- **THEN** the "Temporarily closed" chip is shown

#### Scenario: TC with a virtual link is not closed

- **WHEN** `formats` is `O,TC` and `virtual_meeting_link` is a URL
- **THEN** no chip is shown

#### Scenario: A key that only contains TC is not closed

- **WHEN** `formats` is `O,ATC` and `virtual_meeting_link` is empty
- **THEN** no chip is shown

### Requirement: Format definitions and cache

Format definitions SHALL be fetched from both GetFormats queries
(`lang_enum=da` and `lang_enum=en`), concatenated, and cached under the key
`meetingFormatsCache` as `{fetchedAt: <epoch ms>, formats: [...]}` for 7 days
(`7 * 24 * 60 * 60 * 1000` ms). `formats` holds the rows as the server sent
them. On fetch failure the stale cache is used if present, else an empty
list, and a retry is allowed after 60 s. The cache is never written empty.
Definitions are fetched at most once at a time; concurrent requests share
the same fetch.

#### Scenario: Fresh cache avoids the network

- **WHEN** the cache was written 3 days ago
- **THEN** no GetFormats request is made

#### Scenario: Stale cache used when offline

- **WHEN** the cache is 8 days old and the network fails
- **THEN** the cached formats are used

#### Scenario: Failure allows retry after a minute

- **WHEN** the fetch fails with no cache
- **THEN** meetings show raw keys as chips and a new fetch is attempted on the first request after 60 s

#### Scenario: Concurrent meetings share one fetch

- **WHEN** twenty meeting cards request their formats while the cache is empty
- **THEN** exactly one pair of GetFormats requests is made
