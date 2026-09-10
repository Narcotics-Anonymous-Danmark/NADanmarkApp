# Meetings Map Specification

## Purpose

The Map page shows meetings as pins on a Google map around the user, re-searches
as the map moves, clusters dense areas, lets the user jump to a place by name,
and opens the meeting details for a pin.

> Source: App/src/app/pages/map-search/map-search.page.{ts,html}, App/src/app/providers/meeting-list.service.ts (legacy)

## Requirements

### Requirement: Initial camera

The map SHALL open at zoom 8 centred on the device position when location
permission is granted and a position arrives within 10 s; otherwise on the
default coordinates lat `55.476224`, lng `8.4606976`. Without permission the map
is drawn at the default immediately without prompting. "Locating…" is shown in
the loading bar while waiting. The map shows the my-location dot, the
my-location button, compass and zoom controls.

#### Scenario: Position arrives in time

- **WHEN** permission is granted and a position arrives after 3 s
- **THEN** the map is centred on that position at zoom 8

#### Scenario: Position times out

- **WHEN** permission is granted and no position arrives for 10 s
- **THEN** the map is centred on 55.476224, 8.4606976 at zoom 8

#### Scenario: No permission draws immediately

- **WHEN** permission is not granted
- **THEN** the map is drawn at the default coordinates without a permission prompt

### Requirement: Initial search

The app SHALL run a first search as soon as the map is ready, on both
platforms, using the camera target, zoom and the far-left corner of the visible
region.

#### Scenario: First search runs on map ready

- **WHEN** the map reports ready
- **THEN** one radius search runs for the camera target with the auto radius

### Requirement: Auto radius

The search radius SHALL be the great-circle distance in km from the camera
target to the far-left corner of the visible region, multiplied by 1.1
(`autoRadius = distance(target, farLeft) / 1000 * 1.1`). The radius search uses
the Tomato map-pins query with `data_field_key=longitude,latitude,id_bigint`.

#### Scenario: Radius follows the visible region

- **WHEN** the centre-to-far-left distance is 20 km
- **THEN** the search uses `geo_width_km=22`

### Requirement: Re-search on camera move

After a camera move ends (and no drag is in progress) the app SHALL re-search
only when the distance in km between the last searched centre and the new
centre exceeds `autoRadius / 11`, or the new zoom is lower (zoomed out) than the
zoom of the last search. Otherwise existing pins stay. A re-search clears all
pins and clusters first and shows "Finding meetings…" in the loading bar.

#### Scenario: Small pan keeps pins

- **WHEN** the auto radius is 22 km and the user pans 1 km at the same zoom
- **THEN** no new search runs

#### Scenario: Large pan re-searches

- **WHEN** the auto radius is 22 km and the user pans 3 km
- **THEN** pins are cleared and a new search runs from the new centre

#### Scenario: Zooming out re-searches

- **WHEN** the user zooms from 10 to 9 without panning
- **THEN** a new search runs

### Requirement: Pins for visible meetings

Each returned meeting with numeric `latitude` and `longitude` inside the
visible region SHALL get a pin. Consecutive meetings in the response whose
latitude and longitude both round to the same 3 decimals
(`round(x * 1000) / 1000`) are co-located: they SHALL be one red pin carrying
all their ids; a meeting with no co-located neighbour gets a blue pin with its
id. Pins never auto-pan the camera.

#### Scenario: Co-located meetings become one red pin

- **WHEN** three consecutive meetings are at 55.6761/12.5683, 55.6762/12.5683 and 55.6761/12.5684 (all rounding to 55.676/12.568)
- **THEN** one red pin is placed carrying the three ids

#### Scenario: Distinct meetings get blue pins

- **WHEN** two meetings are 500 m apart
- **THEN** two blue pins are placed, each with one id

#### Scenario: Meetings outside the view are skipped

- **WHEN** a returned meeting lies outside the visible region
- **THEN** no pin is created for it

### Requirement: Clustering

Pins SHALL be clustered with these bucket icons by cluster size: 3–10 (m1,
anchor 16/16), 11–50 (m2, 16/16), 51–100 (m3, 24/24), 101–500 (m4, 24/24),
501+ (m5, 32/32); the count is drawn in white bold 15 pt. Two pins never form a
cluster. Tapping a cluster zooms into it; tapping a pin opens the details.

#### Scenario: Three close pins cluster

- **WHEN** three pins fall in the same cluster cell at the current zoom
- **THEN** one cluster icon m1 with the label "3" replaces them

#### Scenario: Two close pins stay pins

- **WHEN** only two pins fall in the same cell
- **THEN** both pins remain visible

### Requirement: Tap pin opens details

Tapping a pin SHALL fetch the meetings for its ids from Tomato and open the
meeting details modal with one card per meeting.

#### Scenario: Blue pin opens one meeting

- **WHEN** the user taps a blue pin with id 123
- **THEN** the details modal opens with the card for meeting 123

#### Scenario: Red pin opens all co-located meetings

- **WHEN** the user taps a red pin with ids 123, 456
- **THEN** the details modal lists both meetings

### Requirement: Places search

The header SHALL hold a search field (placeholder "Search" (Søg)). Typing
requests place predictions from Google Places autocomplete and lists them under
the field; clearing the field clears the list. Selecting a prediction geocodes
its description, drops a marker titled with the description (replacing any
previous search marker), moves the camera to it at zoom 10 and shows the marker
info window; tapping the marker toggles the info window. The camera move then
triggers the normal re-search rule.

#### Scenario: Predictions appear while typing

- **WHEN** the user types "Aarh"
- **THEN** the predictions returned by autocomplete are listed under the field

#### Scenario: Selecting a place moves the camera

- **WHEN** the user selects "Aarhus, Denmark"
- **THEN** a marker titled "Aarhus, Denmark" is placed, the camera moves there at zoom 10 and the prediction list is cleared

### Requirement: API key configuration

The Google Maps and Places keys SHALL come from `GOOGLE_MAPS_API_KEY` in the
`--dart-define-from-file` environment; an empty key renders the page with a
visible "Map unavailable" state instead of crashing.

#### Scenario: Missing key degrades gracefully

- **WHEN** `GOOGLE_MAPS_API_KEY` is empty
- **THEN** the map page shows "Map unavailable" and the rest of the app works

## Intentional deltas from the legacy app

- Legacy triggered the initial search explicitly only on iOS (`trigger_initial_search`); on Android it relied on the first camera-move event. The initial search runs on both platforms.
- Legacy placed an invisible zero-size marker for every member of a co-located group except the last, plus the red pin. Only the red pin is created.
- Legacy ids were carried as a pre-built `&meeting_ids[]=` query fragment; ids are a typed list and the query is built by the adapter.
- Legacy loaded marker PNGs as base64 on iOS and file paths on Android; assets are bundled once.
- Legacy used the Places JavaScript SDK loaded in `index.html`; the rewrite calls the Places HTTPS API through an adapter with the same key.
- The stray `)` in the legacy `openMapsLink` URL on the map page is not reproduced; directions come from the meeting card.
