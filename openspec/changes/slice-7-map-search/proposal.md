# Slice 7: map search

## Why

The map is the last legacy page still missing. It is the quickest way to see
which meetings are near a place, not just near the user. It is also the
riskiest port: a native platform view, an API key on both platforms, the
search-as-you-pan rules (auto radius, re-search threshold), co-located pins and
clustering. The meeting details modal and the meetings-by-id query were
deferred to this slice by slice 1 because the map is their only entry point.

## What Changes

- **Map types** (`na_kernel`, new `maps/` folder):
  - `MapZoom`, `MapCamera`, `MapBounds` (with `farLeft` and `contains`)
  - `GreatCircle.metres` (haversine on the Maps SDK earth radius)
  - `MapRadius` (a fractional km radius with a stable query code)
  - `MeetingSpot` (id + position, one row of the pins query)
  - `MeetingPin` (`SinglePin` / `SharedPin`) and `pinsWithin` (the visible and
    co-located rules)
  - `MapMarker` (`PinMarker`, `ClusterMarker`, `PlaceMarker`), `ClusterBucket`
    and `MarkerClusterer` (pure Dart grid clustering)
  - `PlaceId`, `PlaceQuery`, `PlaceDescription`, `PlacePrediction`
  - `BusyActivity` needs no new value: the map uses `locating` and
    `findingMeetings`.
- **Ports** (`na_ports`):
  - `MeetingSearchPort.meetingSpots({centre, radius})` and
    `MeetingSearchPort.meetingsById({ids})`
  - `PlacesPort` (predictions, location of a place)
  - `MapHandle` (visible bounds, move, fit, toggle info window) and
    `MapEvents` (created, camera moved, camera idle, marker tapped). The
    native map hands a `MapHandle` to the feature, and the feature implements
    `MapEvents`.
- **`adapter_bmlt`**: the pins query (`data_field_key=longitude,latitude,id_bigint`)
  and the by-id query (`meeting_ids[]=` per id) against Tomato.
- **`adapter_places`** (new, `dio`): the Places web service
  (`place/autocomplete/json` and `place/details/json?fields=geometry`) with the
  `GOOGLE_MAPS_API_KEY`.
- **`adapter_google_maps`** (new, `google_maps_flutter`): `GoogleMapSurface`,
  the `GoogleMap` widget drawing a list of `MapMarker`s, the pin and cluster
  icons (legacy PNGs; cluster counts painted at runtime), and
  `GoogleMapHandle`.
- **`feature_meetings`**: the meeting details modal (`showMeetingDetails`,
  "Meeting Details" / "Close", one card per meeting, error with "Try again").
- **`feature_meetings_map`** (new): `MapSearchController` (camera placement,
  search and re-search rules, pins and clusters, taps, place marker),
  `PlaceSearchController` (debounced predictions, newest wins, selection) and
  the page body (search field, suggestions, map, failure banner, "Map
  unavailable").
- **App**: the `/map-search` route renders the page. `AppConfig` reads
  `GOOGLE_MAPS_API_KEY`. An empty key binds `MapsUnavailable`, so the page
  shows "Map unavailable" and nothing calls Google. iOS `AppDelegate` passes
  the `GoogleMapsApiKey` Info.plist value to `GMSServices`.

Legacy behaviour not reproduced (on top of the deltas already in the main
spec):
- A failed pins search left the loader on and the map empty. It now shows an
  error banner with "Try again".
- An older pins result could overwrite a newer one after fast panning. Only
  the newest search counts.
- Places were geocoded by their description text through the platform
  geocoder. They are located by `place_id` through Place Details, which is
  exact and needs no extra native plugin.
- Autocomplete ran on every keystroke. It runs 300 ms after the last
  keystroke, and an older answer never replaces a newer one.
- Cluster counts included the invisible markers of co-located meetings, so
  three meetings at one address showed as a cluster that never split. A
  co-located group is one pin. Clusters need three pins, and the label counts
  meetings.
- Clusters stop at zoom 15, so tapping a cluster always ends on pins.

## Non-goals

- Play Services absence fallback to a list. It is recorded as a risk; the
  nearby page covers the same need.
- Dark map styling (slice 9 dark theme).
- Persisting the last map position between visits.
- A "search this area" button: the legacy automatic re-search rule stays.
- iOS build and screenshots: they join slice 0's open macOS task.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `meetings-map`:
  - "Pins for visible meetings", "Clustering" and "Places search" gain the
    rules above.
  - New requirements "Map search failure", "Newest map search wins" and
    "Leaving the map".
- `meetings-search`: "Meeting details modal" gains the failure state and the
  by-id query string.

## Impact

- **New packages:** `packages/features/feature_meetings_map`,
  `packages/adapters/adapter_places`, `packages/adapters/adapter_google_maps`
  (`google_maps_flutter` 2.18.1, pinned with its platform packages).
- **Extended packages:** `na_kernel`, `na_ports`, `na_testing` (`MapSurfaceMimic`,
  `PlacesMimic`, pins and by-id routes in `BmltServerMimic`, builders),
  `adapter_bmlt`, `feature_meetings`, `na_l10n` (`mapUnavailable`,
  `mapClearSearch`), `app`.
- **Native:** iOS `AppDelegate` (`GMSServices.provideAPIKey`). Android already
  has the `com.google.android.geo.API_KEY` meta-data from Phase A.
- **Configuration:** `coverage.yaml` floors for the new adapters,
  `docs/LEGACY_PARITY.md` rows for the map keys and plugins.
