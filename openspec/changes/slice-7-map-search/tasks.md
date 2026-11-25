# Tasks

## 1. Kernel (D2–D4)

- [x] 1.1 Add `MapZoom`, `MapCamera`, `MapBounds` (`farLeft`, `contains`), `GreatCircle.metres`, `MapRadius` (`auto`, `code`) and `ReSearchRule` under `na_kernel/lib/src/maps/`; verify with table tests (Copenhagen–Aarhus distance against the Maps SDK value, 20 km → `22`, `15.51234` → `15.512`, pan 1 km / 3 km at radius 22, zoom 10 → 9)
- [x] 1.2 Add `MeetingSpot`, `MeetingPin` (`SinglePin`, `SharedPin`) and `pinsWithin`; verify with the spec examples (three co-located, 500 m apart, outside the view, non-consecutive equal positions)
- [x] 1.3 Add `MapMarker` (`PinMarker`, `ClusterMarker`, `PlaceMarker`), `MarkerKey`, `ClusterBucket` and `MarkerClusterer`; verify with tests for 3 pins → m1 "3", 2 pins → pins, red pin counted by ids, bucket edges 10/11/50/51/100/101/500/501, no clusters at zoom 15, stable order
- [x] 1.4 Add `PlaceId`, `PlaceQuery`, `PlaceDescription`, `PlacePrediction`, the Places wire DTOs + `PlacesMapper`, the `BmltSpotDto` + `BmltMapper.spots`; generate with `./bin/na gen json`; verify with mapper tests on recorded fixtures

## 2. Ports, mimics and builders (D5, D6, D14)

- [x] 2.1 Add `meetingSpots` / `meetingsById` to `MeetingSearchPort`, and `PlacesPort`, `MapHandle`, `MapEvents` to `na_ports`; verify that the unbound-port test lists `PlacesPort`
- [x] 2.2 Extend `MeetingSearchMimic` and `BmltServerMimic` (spots and by-id routes, held replies), add `PlacesMimic`, `PlacesServerMimic` and `MapSurfaceMimic` (implements `MapHandle`, auto created → idle, pan/zoom/tap helpers, recorded moves), bind `PlacesMimic` in `TestContainer`; verify with mimic unit tests

## 3. Acceptance tests first (red)

- [x] 3.1 Add `app/test_acceptance/support/map.dart` (pump with `MapSurfaceMimic`, `PlacesMimic`, a `BmltServerMimic`) and write one `testWidgets` per scenario of `meetings-map` and of "Meeting details modal" in `app/test_acceptance/meetings_map/`; verify they fail because the page is missing

## 4. Adapters (D10–D12)

- [x] 4.1 Add `BmltEndpoints.meetingSpots` / `meetingsById` and the `DioMeetingSearch` methods; verify with adapter tests on exact URIs, `{}` / `[]`, network and decode failures
- [x] 4.2 Create `adapter_places` (`DioPlaces`, `placesOverrides`); verify with tests for OK, ZERO_RESULTS, REQUEST_DENIED, network failure, details OK and details without geometry
- [x] 4.3 Pin `google_maps_flutter` 2.18.1 and its platform packages, create `adapter_google_maps` (`GoogleMapSurface`, `GoogleMapHandle`, `MarkerIcons`, legacy PNG assets); verify with tests against a fake on `MethodChannelGoogleMapsFlutter` with the platform-view channel mocked (configuration, markers, taps, camera events, handle calls) and painter tests

## 5. Features (D7–D10)

- [x] 5.1 Add `MeetingIds`, `meetingDetailsProvider` and `showMeetingDetails` to `feature_meetings`; verify with widget tests and goldens (loading, loaded, error)
- [x] 5.2 Create `feature_meetings_map` with `MapAvailability`, `MapSearchController` and `PlaceSearchController`; verify with `TestTime` unit tests for every rule (placement with fix / timeout / no permission, first idle, re-search rule, re-cluster, newest wins, failure + retry, taps, place flow, debounce, dispose)
- [x] 5.3 Build `MapSearchBody` (unavailable, placing, drawn, suggestions, failure banner, details listener); verify with widget tests, goldens and `expectAccessible`

## 6. App wiring and native (D6, D11, D13)

- [x] 6.1 Add `mapUnavailable` and `mapClearSearch` to both ARB files and regenerate; update `docs/LEGACY_PARITY.md`; verify with `./bin/na check arb`
- [x] 6.2 Read `GOOGLE_MAPS_API_KEY` in `AppConfig`, bind `mapAvailabilityProvider` and `placesOverrides`, render the `map` route; verify that the acceptance tests from 3.1 pass
- [ ] 6.3 Call `GMSServices.provideAPIKey` from the `GoogleMapsApiKey` Info.plist value in `AppDelegate.swift`; verify the iOS build under slice 0's open macOS task
- [x] 6.4 Add the new packages to the workspace and `app/pubspec.yaml` (`coverage.yaml` needs no entry: the adapter default of 80 % and the feature default of 95 % apply); verify with `./bin/na check deps`

## 7. End to end and definition of done

- [x] 7.1 Add the Patrol test `app/integration_test/map_search_test.dart`; verify with `./bin/na test e2e --device <android emulator>` (with `env/test.json` the key is empty, so CI covers the "Map unavailable" path; the native map, clusters, pin details and Places search were checked by hand on the `android-35` emulator with `env/dev.json`)
- [x] 7.2 Capture da/en Android screenshots of the map into `docs/screenshots/meetings-map/` (map, details, place suggestions, chosen place)
- [x] 7.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --check`

## 8. Device findings

- [x] 8.1 Open the place info window on the camera idle after the move (opening it right after `moveTo` raced the native marker update) and unfocus the search field when a suggestion is chosen; verify on the emulator and with the controller and acceptance tests
- [x] 8.2 Key the "Map unavailable" card itself, so Patrol's `waitUntilVisible` can hit-test it

## Workflow follow-up

- On archive, add the proposal's "Legacy behaviour not reproduced" items to "Intentional deltas from the legacy app" in `openspec/specs/meetings-map/spec.md`.
- Archive with `/opsx:archive slice-7-map-search` after the PR is merged.
