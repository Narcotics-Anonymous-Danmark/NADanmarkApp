# Spec Delta

## MODIFIED Requirements

### Requirement: Meetings nearby

The "Meetings nearby" page (`/location-search`) SHALL search the Tomato radius
endpoint around the device position with the radius from the `searchRange`
setting (default 15). A footer holds a "Meetings nearby" button that re-locates
the device and a radius slider 5–50 km (labels "5 km", "50 km") that re-runs the
search 500 ms after the last change without re-locating. Above the slider the
current value reads "Search radius: <n> km" (Søgeradius: <n> km) and follows
the knob while dragging. The slider changes only this page's search; it never
writes `searchRange`. Results are shown in
the shared meeting list. When no position could be determined the default
coordinates lat `55.476224`, lng `8.4606976` are used. Only the newest search
counts: a result that arrives after a newer search started SHALL be discarded.
While a new search runs, the previous results stay visible.

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

#### Scenario: Slider shows the current radius

- **WHEN** `searchRange` is 20 and the user drags the slider to 35
- **THEN** the label reads "Search radius: 20 km" before the drag and "Search radius: 35 km" after it

#### Scenario: Slider does not change the setting

- **WHEN** `searchRange` is 15 and the user moves the page slider to 40
- **THEN** `searchRange` is still 15
- **AND** the next visit to the page starts at 15

#### Scenario: Older result is discarded

- **WHEN** a search at 15 km is pending, the user moves the slider to 30 and the 30 km result arrives before the 15 km result
- **THEN** the list shows the 30 km meetings
- **AND** it still shows them after the 15 km result arrives

#### Scenario: Previous results stay while searching again

- **WHEN** the list shows meetings and the user moves the slider
- **THEN** the meetings stay visible until the new result replaces them

### Requirement: Location acquisition and timeouts

Locating SHALL show "Locating…" (Finder position …) in the loading bar. The
timeout is 10 s when location permission is already granted and 45 s when it is
not (to allow the permission prompt). On timeout the search runs with the
current best coordinates (default if none); if a position arrives after the
timeout the search runs again with the real position. When permission is
refused or location services are off, the search SHALL run at once with the
current best coordinates. The "Meetings nearby" button locates again; until a
new position arrives the last real position stays the best coordinates.

#### Scenario: Permission granted times out after 10 seconds

- **WHEN** permission is granted and no position arrives for 10 s
- **THEN** the loading bar hides and the search runs with the default coordinates

#### Scenario: Late position triggers a second search

- **WHEN** the position arrives 12 s after a 10 s timeout
- **THEN** a second search runs with the real coordinates and replaces the list

#### Scenario: Without permission the timeout is 45 seconds

- **WHEN** permission is not granted and the user does not answer the prompt
- **THEN** the search runs with default coordinates after 45 s

#### Scenario: Refused permission searches at once

- **WHEN** the user refuses the location permission prompt
- **THEN** the search runs immediately with the default coordinates and "Locating…" is hidden

#### Scenario: Location services off searches at once

- **WHEN** permission is granted but location services are turned off
- **THEN** the search runs immediately with the default coordinates

#### Scenario: Relocating keeps the last real position

- **WHEN** a search ran at lat 56.15, lng 10.2 and the user taps "Meetings nearby" and no position arrives for 10 s
- **THEN** the search runs again at lat 56.15, lng 10.2

### Requirement: Day and hour filters

Above the sections the list SHALL offer a day selector and a dual-knob hour
range 0–23 (step 1). The day row reads "Day" (Dag) and shows "All days" (Alle
dage) or the selected weekdays in `firstday` order, comma separated. Tapping it
opens a sheet with one checkbox per weekday in `firstday` order, "Cancel"
(Annuller) and "OK"; any number of days can be checked, and confirming with
none or all seven checked means "All days". The hour row shows the range as
"<lower>:00 – <upper>:59". A meeting passes when its weekday is selected (or
"All days") and its start hour is between the knobs inclusive. Filtering
re-computes the per-day counts. The hour filter applies 350 ms after the last
change.

#### Scenario: Day filter keeps one section

- **WHEN** the user checks only "Friday" and confirms
- **THEN** only the Friday section is shown with its count

#### Scenario: Several days can be selected

- **WHEN** the user checks "Monday" and "Friday" and confirms
- **THEN** only the Monday and Friday sections are shown
- **AND** the day row reads "Monday, Friday"

#### Scenario: Unchecking every day shows all days

- **WHEN** "Friday" is selected and the user unchecks it and confirms
- **THEN** every day section is shown and the day row reads "All days"

#### Scenario: Cancel keeps the selected days

- **WHEN** "Friday" is selected and the user checks "Monday" and taps "Cancel"
- **THEN** only the Friday section is shown

#### Scenario: Hour range filters by start hour

- **WHEN** the range is 18–20
- **THEN** meetings starting 18:00–20:59 are listed and a 17:30 meeting is not

#### Scenario: Hour range shows its hours

- **WHEN** the list opens and the user drags the knobs to 18 and 20
- **THEN** the hour row reads "00:00 – 23:59" before the drag and "18:00 – 20:59" after it

## ADDED Requirements

### Requirement: Nearby results states

The page SHALL show "Nothing found" (Intet fundet) when the radius query
returns no meetings. When the query fails it SHALL show "The meetings could not
be loaded" (Møderne kunne ikke hentes) with a "Try again" (Prøv igen) button
that repeats the search with the same coordinates and radius, and the loading
bar SHALL be hidden.

#### Scenario: No meetings in range

- **WHEN** the radius query returns `{}`
- **THEN** the page shows "Nothing found" and the loading bar is hidden

#### Scenario: Failed nearby search can be retried

- **WHEN** the radius query fails and the user taps "Try again" after the server recovers
- **THEN** the same coordinates and radius are queried and the meetings replace the error

### Requirement: Unknown position is disclosed

When the search used the default coordinates, the error "Location not set"
(Placeringen er ikke indstillet) SHALL be shown above the results, in the same
error style as every other error message.

#### Scenario: Default coordinates are disclosed

- **WHEN** no position could be determined and the search ran on the default coordinates
- **THEN** "Location not set" is shown above the results in the error style used by "The meetings could not be loaded"

#### Scenario: Real position shows no location error

- **WHEN** the search ran on the device position
- **THEN** "Location not set" is not shown

### Requirement: Location permission

The app SHALL request location only while in use, never in the background, and
only from the "Meetings nearby" page in this capability. Approximate location
SHALL be enough to search. The iOS purpose text is "Location will be used to
show NA meetings in your area, in the meeting list and on the map. Your
location is only used locally on your device." The position SHALL never be
stored or sent anywhere other than the radius query.

#### Scenario: Approximate location is accepted

- **WHEN** the user grants only approximate location on Android
- **THEN** the search runs on the approximate position and "Location not set" is not shown

#### Scenario: Permission is not requested elsewhere

- **WHEN** the user opens Home, Meetings and Settings without visiting "Meetings nearby"
- **THEN** no location permission prompt is shown

#### Scenario: Position is not persisted

- **WHEN** a nearby search has run on the device position
- **THEN** no stored setting contains the coordinates
