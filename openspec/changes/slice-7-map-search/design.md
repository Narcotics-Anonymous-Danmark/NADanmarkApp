# Design

## Context

Earlier slices provide:
- the Tomato radius query, `BmltJson`, `BmltMapper` and `BmltServerMimic`
  (slice 2)
- `GeolocationPort` with separate `access()` / `currentPosition()`, so the map
  can locate without prompting (slice 2, D3)
- `BusyTracker.begin()` spans and the "Locating…" / "Finding meetings…" texts
- `MeetingCard`, the formats index and `showNaPopover` (slice 1)
- `NaSearchField` (slice 5), `Scheduler.debounce`, `TestTime`
- the Android `com.google.android.geo.API_KEY` placeholder and the iOS
  `Secrets.xcconfig` → `GoogleMapsApiKey` Info.plist entry (Phase A)

Constraints:
- `LayerRules`: features never import adapters, adapters never import
  features or `na_design`, ports never depend on Flutter. The `GoogleMap`
  widget therefore cannot be referenced by the feature. It also cannot be
  referenced by a port.
- `GoogleMap` is a platform view: widget and acceptance tests cannot render
  it, so the page must run against a stand-in.
- The dev key allows the Places web service (`maps/api/place/*`) and not
  Places (New) or the Geocoding API (checked with `curl` on 2026-11-25).

## Goals / Non-Goals

**Goals:**
- Every map rule (auto radius, re-search threshold, co-location, clustering,
  newest wins) is pure Dart and unit-tested without a map.
- Acceptance tests drive the real page, controllers, BMLT adapter and Places
  adapter against mimics, with a map stand-in that behaves like the plugin
  (created → camera idle).
- The native surface is one thin adapter.

**Non-Goals:**
- Native clustering (`ClusterManager`). It cannot draw the legacy bucket icons
  or the count label, its minimum cluster size differs between Android and
  iOS, and its result is invisible to tests. The plan asked for pure Dart
  clustering.
- Marker animations, custom map styles.

## Decisions

### D1 Packages

- `na_kernel/lib/src/maps/`: value types and the pure rules (D2–D4).
- `na_ports/lib/src/maps/`: `MapHandle`, `MapEvents`, `PlacesPort`.
- `adapter_bmlt`: `BmltEndpoints.meetingSpots` / `meetingsById`,
  `DioMeetingSearch.meetingSpots` / `meetingsById`, `BmltMapper.spots`.
- `adapter_places` (new): `DioPlaces implements PlacesPort`.
- `adapter_google_maps` (new): `GoogleMapSurface` (stateless widget),
  `GoogleMapHandle implements MapHandle`, `MarkerIcons`.
- `feature_meetings` (bridge library): `MeetingDetails` modal and
  `meetingDetailsProvider`. The modal is a meetings component; the map only
  opens it.
- `feature_meetings_map` (new): controllers and page body. It is a separate
  package because `meetings-map` is a separate capability, as
  `feature_events` was. It imports only the bridge `feature_meetings`.

### D2 Geometry

- `GreatCircle.metres(a, b)`: haversine with `R = 6371009 m`, the radius the
  Maps SDK `Spherical.computeDistanceBetween` uses, so distances match the
  legacy numbers.
- `MapBounds { southWest, northEast }`. `farLeft` is `(north, west)`.
  `contains` is inclusive and does not handle the antimeridian (Denmark).
- `MapRadius(double km)`. `MapRadius.auto(target:, farLeft:)` =
  `metres / 1000 * 1.1`. `code` rounds to 3 decimals and drops trailing
  zeros: 20 km → `22` (not `22.000000000000004`), 15.51234 → `15.512`.
- `ReSearchRule.isDue(last:, camera:)`: `km(last.centre, camera.target) >
  last.radius.km / 11 || camera.zoom < last.zoom`.

### D3 Pins

`MeetingSpot { MeetingId id; GeoPoint point }` is one row of the pins query.
`pinsWithin(spots:, bounds:)`:
1. Drop spots outside `bounds`.
2. Walk the rest in response order and group consecutive spots whose
   `round(x * 1000) / 1000` latitude and longitude are equal.
3. A group of one is a `SinglePin(id, point)`. A larger group is a
   `SharedPin(ids, point of the first member)`.

Filtering before grouping means a group never mixes visible and invisible
meetings. Legacy checked only the first member.

### D4 Clustering

`MarkerClusterer.cluster(pins:, zoom:)` (in `na_kernel`, next to the other
pure map rules):
- Project each pin to Web Mercator world pixels at `256 · 2^zoom`, and bucket
  it by a 64 px grid cell.
- A cell with three or more pins becomes a `ClusterMarker` at the average
  position of its pins, carrying the pins. Cells with fewer pins keep their
  `PinMarker`s.
- At zoom ≥ 15 nothing clusters.
- `ClusterMarker.meetings` = sum of ids. `ClusterBucket.of(meetings)`:
  3–10 m1, 11–50 m2, 51–100 m3, 101–500 m4, 501+ m5. A cluster always has
  at least three meetings, because it has at least three pins.
- Output order is stable: cells in first-seen order. Marker keys are
  `pin-<first id>`, `cluster-<first id of its first pin>` and `place`.

Alternative: count markers like the legacy plugin (invisible markers
included). Rejected; see the proposal.

### D5 Ports

```dart
abstract interface class MeetingSearchPort {
  ...
  Future<Outcome<List<MeetingSpot>, Failure>> meetingSpots({
    required GeoPoint centre, required MapRadius radius});
  Future<Outcome<List<Meeting>, Failure>> meetingsById({
    required List<MeetingId> ids});
}

abstract interface class PlacesPort {
  Future<Outcome<List<PlacePrediction>, Failure>> predictions({
    required PlaceQuery query, required Language language});
  Future<Outcome<GeoPoint, Failure>> locate({required PlaceId place});
}

abstract interface class MapHandle {
  Future<MapBounds> visibleBounds();
  Future<void> moveTo({required MapCamera camera});
  Future<void> fit({required MapBounds bounds});
  Future<void> toggleInfo({required MarkerKey marker});
  Future<void> showInfo({required MarkerKey marker});
}

abstract interface class MapEvents {
  void created({required MapHandle handle});
  void cameraMoved({required MapCamera camera});
  void cameraIdle();
  void markerTapped({required MarkerKey marker});
}
```

`MapHandle` / `MapEvents` are plain Dart, so `na_ports` stays Flutter-free.

### D6 Map surface slot

`feature_meetings_map` declares:

```dart
typedef MapSurface = Widget Function({
  required MapCamera initial,
  required MyLocationLayer myLocation,
  required List<MapMarker> markers,
  required MapEvents events,
});

sealed class MapAvailability {}
final class MapsAvailable extends MapAvailability { final MapSurface surface; }
final class MapsUnavailable extends MapAvailability {}

final Provider<MapAvailability> mapAvailabilityProvider = unboundPort(...);
```

- **Production:** `app` binds `MapsAvailable(surface: GoogleMapSurface.new-like
  function)` when `GOOGLE_MAPS_API_KEY` is set, else `MapsUnavailable`.
- **Tests:** `MapSurfaceMimic` in `na_testing` has a `build` method with the
  same named parameters. Its tear-off fits the typedef without `na_testing`
  importing the feature.
- **Why a function slot and not a port:** the slot returns a `Widget`, which
  ports may not reference. Constructor injection through the router was
  rejected because acceptance tests use the real router.

### D7 MapSearchController

An `autoDispose` `Notifier<MapSearchState>` that also implements `MapEvents`.
Its single instance is the events object for the page, so the surface's
callbacks are stable.

```dart
final class MapSearchState {
  final MapStage stage;           // PlacingCamera | MapDrawn(initial, myLocation)
  final List<MapMarker> markers;  // clustered for the current zoom, plus place
  final MapSearchStatus status;   // enum: notSearched, searching, searched, failed
  final DetailsRequest details;   // NoDetails | DetailsFor(ids, token)
}
```

- **Camera placement** (`build` → microtask):
  - `access()`. If not `granted`: draw at `GeoPoint.searchFallback`, zoom 8,
    with no prompt.
  - If `granted`: open a `locating` span and start a 10 s
    `Scheduler.after`, then call `currentPosition()`. The first of fix /
    failure / timeout decides: `Located` → that point, anything else → the
    fallback. A fix after the timeout is ignored, because the map is already
    drawn.
  - `myLocation` is `shown` only when access is `granted`.
- **Events:**
  - `created` stores the handle.
  - `cameraMoved` stores the latest camera, initially the drawn one.
  - `cameraIdle`:
    - first idle → search;
    - otherwise `ReSearchRule` → search;
    - otherwise re-cluster the current pins at the new zoom.
- **Search:**
  - Take a generation ticket and set `Searching`.
  - Clear pin and cluster markers; the place marker stays.
  - Open a `findingMeetings` span and `await handle.visibleBounds()`.
  - Compute `MapRadius.auto` and record `last = (centre, zoom, radius)`
    before the request, so idles during the request compare against it.
  - Call `meetingSpots`. A stale ticket is dropped. `Ok` → `pinsWithin` →
    `MarkerClusterer.cluster` at the latest zoom. `Err` → `MapSearchFailed`.
- **`retry()`** searches again with the latest camera.
- **`markerTapped`:**
  - `pin-*` → `DetailsFor(ids)` with a fresh token; the page shows the modal.
  - `cluster-*` → `handle.fit(bounds of its pins)`.
  - `place` → `handle.toggleInfo`.
- **`showPlace(description, point)`:** replace the place marker, remember
  that its info window is due, then `moveTo(zoom 10)`. The next camera idle
  opens the info window (as legacy did after `moveCamera` resolved) and then
  follows the normal re-search rule. Opening it right after `moveTo` raced
  the native marker update on the emulator: the window never appeared.
- **Dispose:** cancel the timeout and end every open span.

### D8 PlaceSearchController

An `autoDispose` `Notifier<PlaceSearchState { PlaceQuery query; Suggestions
suggestions }>`.
- **`type(query)`:**
  - empty → `NoSuggestions` at once and the pending debounce is cancelled;
  - otherwise a `Scheduler.debounce(300 ms)` → `predictions(query,
    language)`. A generation ticket drops older answers, and `Err` →
    `NoSuggestions`.
- **`choose(prediction)`:**
  - set the query to the description and clear the suggestions;
  - `locate(place)` → `Ok` → `MapSearchController.showPlace`. `Err` is
    ignored, as in legacy.
- **Language:** read once from `SettingsPort` and passed to Places
  (`language=da|en`).

### D9 Page

`MapSearchBody` (ConsumerWidget):
- `MapsUnavailable` → `NaErrorState(mapUnavailable)`.
- `MapsAvailable`: a column of
  - the `NaSearchField` (placeholder `mapsearchSearch`, clear label
    `mapClearSearch`)
  - an `Expanded` stack of:
    - `PlacingCamera` → an empty surface-coloured box; `MapDrawn` → the
      surface;
    - the suggestions list (`NaListBlock` of rows keyed
      `place-suggestion-<index>`) when there are any;
    - `MapSearchFailed` → an `NaErrorState` card with a "Try again" button at
      the top.
- **Details modal:** `ref.listen` on `details` → `showMeetingDetails(ids)`.
- **Gestures:** the surface gets an `EagerGestureRecognizer`, so pans and
  pinches go to the map, not to the drawer.

### D10 Meeting details modal

- `meetingDetailsProvider` is an `autoDispose` family `FutureProvider` over
  `MeetingIds` (a value list type). It runs under a `findingMeetings` span.
- `showMeetingDetails` opens `showNaPopover` (title `meetingDetails`, close
  `close`) with:
  - loading → `NaSpinner`;
  - error → `NaErrorState(meetingsLoadFailed)` + "Try again";
  - loaded → one `MeetingCard` per meeting in response order.
- The by-id URL is `<tomato>?switcher=GetSearchResults&meeting_ids[]=1&meeting_ids[]=2`.
  Dart's `Uri` sends the brackets as `%5B%5D`; Tomato decodes them (checked
  with `curl` on 2026-11-25). The mimic routes the request by the decoded
  `meeting_ids[]` key.

### D11 adapter_google_maps

- `GoogleMapSurface` (StatelessWidget):
  - `GoogleMap` with `initialCameraPosition`, compass, zoom controls,
    toolbar, buildings, and `myLocationEnabled` / `myLocationButtonEnabled`
    from `MyLocationLayer`;
  - `onMapCreated` → `events.created(GoogleMapHandle(controller))`,
    `onCameraMove` → `cameraMoved`, `onCameraIdle` → `cameraIdle`.
- **Markers:** markers are built in a `FutureBuilder` whose future is
  memoised per `markers` list in an `Expando`, because cluster icons are
  painted asynchronously. The previous marker set stays while the next one
  is painted.
  - Pins use `AssetMapBitmap` (blue / red legacy PNGs, 28 × 34 logical,
    anchor bottom centre).
  - Clusters use `BytesMapBitmap`: the bucket PNG with the count drawn in
    white bold 15 pt, anchor centre, cached per (bucket, count).
  - The place marker is the default marker with an `InfoWindow` titled with
    the description.
  - Every marker has `consumeTapEvents: true`, so a tap never auto-pans.
- **`GoogleMapHandle`:**
  - `getVisibleRegion` → `MapBounds`;
  - `animateCamera(newCameraPosition | newLatLngBounds(padding 48))`;
  - `isMarkerInfoWindowShown` / `show` / `hide`.
- **Tests:** a fake extends the plugin's `MethodChannelGoogleMapsFlutter` and
  overrides only the data calls (markers, camera, region, info windows,
  event streams). The `AndroidView` stays real, with
  `SystemChannels.platform_views` mocked at the wire. That avoids overriding
  the platform's `build*` methods, which `avoid_build_helper_methods`
  rejects. The painter is tested on its output size.
- **Pins:**
  - `google_maps_flutter` 2.18.1, `google_maps_flutter_android` 2.19.10,
    `google_maps_flutter_ios` 2.18.7 and
    `google_maps_flutter_platform_interface` 2.17.0: the newest releases
    that accept Flutter 3.41.3 (2.18.2+ need 3.47, android 2.19.11+ needs
    3.44, platform_interface 2.18 needs 3.44).

### D12 adapter_places

`DioPlaces(dio, key: MapsApiKey)`:
- **Predictions:** `GET
  https://maps.googleapis.com/maps/api/place/autocomplete/json?input=<q>&language=<da|en>&key=<k>`.
  `status` `OK` → predictions (`description`, `place_id`), `ZERO_RESULTS` →
  empty, any other status → `UnavailableFailure`.
- **Location:** `GET …/place/details/json?place_id=<id>&fields=geometry&key=<k>`
  → `result.geometry.location`.
- **Wire:** json_serializable DTOs in `na_kernel/boundary` (`PlacesWire`),
  mapped by `PlacesMapper`.

### D13 Localisation

- **New keys:**
  - `mapUnavailable` ("Map unavailable" / "Kortet er ikke tilgængeligt"),
    listed as planned in `LEGACY_PARITY.md`;
  - `mapClearSearch` ("Clear search" / "Ryd søgning").
- **Reused keys:** `mapsearchSearch`, `meetingDetails`, `close`,
  `meetingsLoadFailed`, `tryAgain`.

### D14 Tests

- **Unit:**
  - kernel table tests for distance, auto radius, `code`, `ReSearchRule`,
    `pinsWithin` and clustering;
  - controller tests per scenario on `TestTime`, `MapSurfaceMimic` as the
    handle, and the port mimics;
  - adapter tests on `BmltServerMimic` and a `PlacesServerMimic`
    (`HttpClientAdapter`) with recorded fixtures.
- **Widget + goldens:** body states (placing, drawn with pins, suggestions,
  failure, unavailable) and the details modal (loading, loaded, error).
- **Acceptance:** `app/test_acceptance/meetings_map/`, one `testWidgets` per
  scenario of `meetings-map` and the details modal scenarios.
  `MapSurfaceMimic` stands in for the native map.
- **Patrol:** `map_search_test.dart` opens the map and expects a
  `GoogleMap`. Markers are native, so the flow checks that the page renders
  and the loading bar finishes.

## Risks / Trade-offs

- **[Risk]** `getVisibleRegion` can return zeros before the first layout on
  Android. → The first search runs on the first camera idle, which the
  plugin emits after layout, not on `onMapCreated`.
- **[Risk]** Devices without Play Services render a blank map. → Not handled
  in this slice (see non-goals); "Meetings nearby" covers the use case.
- **[Risk]** The key is not restricted to the app ids, so it can be used from
  anywhere. → An operations task: restrict the key to Maps SDK + Places with
  Android / iOS app restrictions once the Flutter build replaces the legacy
  app. App restrictions do not apply to the web service calls, so Places may
  need its own key then.
- **[Trade-off]** Pins are filtered at search time, so a small pan reveals
  an empty strip until the threshold triggers a re-search. This is legacy
  behaviour, and the 10 % margin keeps the strip small.
- **[Trade-off]** `GoogleMapSurface` widget code is exercised only through
  the fake platform; the native rendering is verified by Patrol and by hand.

## Migration Plan

No stored data. To roll back, point the `map` route body back to
`SizedBox.shrink()`; the adapters are inert without the page.
