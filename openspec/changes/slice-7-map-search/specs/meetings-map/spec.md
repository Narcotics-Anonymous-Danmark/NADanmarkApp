# Spec Delta

## MODIFIED Requirements

### Requirement: Auto radius

The search radius SHALL be the great-circle distance in km from the camera
target to the far-left (north-west) corner of the visible region, multiplied
by 1.1 (`autoRadius = distance(target, farLeft) / 1000 * 1.1`), with distances
on an earth radius of 6371009 m. The radius search uses the Tomato map-pins
query
`?switcher=GetSearchResults&data_field_key=longitude,latitude,id_bigint&geo_width_km=<r>&long_val=<lng>&lat_val=<lat>&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic`,
with `<r>` rounded to 3 decimals without trailing zeros.

#### Scenario: Radius follows the visible region

- **WHEN** the centre-to-far-left distance is 20 km
- **THEN** the search uses `geo_width_km=22`

#### Scenario: Pins query carries the exact parameters

- **WHEN** the first search runs at 55.476224, 8.4606976 with a 22 km radius
- **THEN** the request is `<tomato>?switcher=GetSearchResults&data_field_key=longitude,latitude,id_bigint&geo_width_km=22&long_val=8.4606976&lat_val=55.476224&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic`

### Requirement: Pins for visible meetings

Each returned meeting with numeric `latitude` and `longitude` inside the
visible region SHALL get a pin; meetings outside it are dropped before
grouping. Consecutive remaining meetings whose latitude and longitude both
round to the same 3 decimals (`round(x * 1000) / 1000`) are co-located: they
SHALL be one red pin carrying all their ids, placed at the first one. A
meeting with no co-located neighbour gets a blue pin with its id. Pins never
auto-pan the camera.

#### Scenario: Co-located meetings become one red pin

- **WHEN** three consecutive meetings are at 55.6761/12.5683, 55.6762/12.5683 and 55.6761/12.5684 (all rounding to 55.676/12.568)
- **THEN** one red pin is placed carrying the three ids

#### Scenario: Distinct meetings get blue pins

- **WHEN** two meetings are 500 m apart
- **THEN** two blue pins are placed, each with one id

#### Scenario: Meetings outside the view are skipped

- **WHEN** a returned meeting lies outside the visible region
- **THEN** no pin is created for it

#### Scenario: Rows without coordinates are skipped

- **WHEN** a returned row has an empty or non-numeric latitude
- **THEN** no pin is created for it and the other rows still get pins

### Requirement: Clustering

Pins SHALL be clustered on a 64 px grid at the current zoom: a cell with
three or more pins becomes one cluster at the average position of its pins,
labelled with the number of meetings it holds (a red pin counts all its ids).
Cells with one or two pins keep their pins. At zoom 15 and above nothing
clusters. The cluster icon depends on that meeting count: 3–10 m1, 11–50 m2,
51–100 m3, 101–500 m4, 501+ m5, anchored at its centre, with the count in
white bold 15 pt. Clusters are recomputed after every camera move, also when
no new search runs. Tapping a cluster moves the camera to fit its pins;
tapping a pin opens the details.

#### Scenario: Three close pins cluster

- **WHEN** three pins fall in the same cluster cell at the current zoom
- **THEN** one cluster icon m1 with the label "3" replaces them

#### Scenario: Two close pins stay pins

- **WHEN** only two pins fall in the same cell
- **THEN** both pins remain visible

#### Scenario: Cluster label counts meetings

- **WHEN** a cell holds two blue pins and a red pin with ids 7, 8, 9
- **THEN** one cluster labelled "5" replaces them

#### Scenario: Tapping a cluster zooms into it

- **WHEN** the user taps a cluster
- **THEN** the camera fits the bounds of the cluster's pins

#### Scenario: No clusters from zoom 15

- **WHEN** three pins share a cell at zoom 15
- **THEN** all three pins are shown

### Requirement: Places search

The header SHALL hold a search field (placeholder "Search" (Søg)) with a clear
button ("Clear search" (Ryd søgning)). 300 ms after the last keystroke the
field's text is sent to Google Places autocomplete in the app language and the
predictions are listed under the field; only the newest answer is shown, and
clearing the field clears the list at once. Selecting a prediction puts its
description in the field, clears the list, locates the place through Place
Details by its `place_id`, drops a marker titled with the description
(replacing any previous search marker), moves the camera to it at zoom 10 and
shows the marker info window; tapping the marker toggles the info window. The
camera move then triggers the normal re-search rule. A failed autocomplete or
Place Details request shows no suggestions and leaves the map as it is.

#### Scenario: Predictions appear while typing

- **WHEN** the user types "Aarh"
- **THEN** the predictions returned by autocomplete are listed under the field

#### Scenario: Autocomplete waits for typing to pause

- **WHEN** the user types "A", "Aa" and "Aar" within 300 ms
- **THEN** one autocomplete request is made, for "Aar"

#### Scenario: Selecting a place moves the camera

- **WHEN** the user selects "Aarhus, Denmark"
- **THEN** a marker titled "Aarhus, Denmark" is placed, the camera moves there at zoom 10 and the prediction list is cleared

#### Scenario: Clearing the field clears the predictions

- **WHEN** predictions are listed and the user clears the field
- **THEN** the list disappears

#### Scenario: Tapping the place marker toggles its info window

- **WHEN** the user taps the search marker
- **THEN** its info window is toggled and the details modal does not open

## ADDED Requirements

### Requirement: Map search failure

A failed pins search SHALL leave the map usable, hide the loading bar and show
"The meetings could not be loaded" (Møderne kunne ikke hentes) with a "Try
again" button over the map. "Try again" searches again from the current
camera; the next successful search removes the message.

#### Scenario: Failure shows an error over the map

- **WHEN** the pins request fails
- **THEN** the error with "Try again" is shown and the loading bar is hidden

#### Scenario: Try again searches the current camera

- **WHEN** the user taps "Try again" after a failure and the request succeeds
- **THEN** the pins are shown and the error is gone

### Requirement: Newest map search wins

When a new pins search starts while another is pending, the result of the
older search SHALL be discarded.

#### Scenario: Older pins result is discarded

- **WHEN** a search is pending, the user pans far enough for a second search and the second result arrives first
- **THEN** only the second result's pins are shown

### Requirement: Leaving the map

Leaving the page SHALL end any "Locating…" or "Finding meetings…" activity in
the loading bar and ignore results that arrive afterwards.

#### Scenario: Leaving during a search hides the loader

- **WHEN** the user opens another page while a pins search is pending
- **THEN** the loading bar is hidden
