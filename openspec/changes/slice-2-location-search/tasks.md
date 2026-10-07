# Tasks

## 1. Kernel (D2, D6)

- [ ] 1.1 Add `LocationAccess`, `PositionFix` (`Located`, `ServicesOff`, `AccessRefused`, `NoFix`), `SearchOrigin` (`DevicePosition`, `DefaultPosition`) and `GeoPoint.searchFallback` under `na_kernel/lib/src/location/`; verify with value-semantics unit tests and a test that `DefaultPosition` resolves to lat 55.476224, lng 8.4606976
- [ ] 1.2 Add `BusyActivity.locating` and `BusyTracker.begin()` returning a `BusySpan` with an idempotent `end()`; verify with unit tests that a span publishes exactly one `BusyStarted` and one `BusyEnded` however often `end()` is called

## 2. Ports, builders and mimics (D3, D5, D10)

- [ ] 2.1 Add `GeolocationPort` with an unbound provider and `MeetingSearchPort.nearbyMeetings({required GeoPoint centre, required Km radius})`; verify that the unbound-port unit test lists the new port
- [ ] 2.2 Add `GeolocationMimic` (scripted access, request answer, delayed or missing fix through `TestTime`, call counts), bind it in `TestContainer` by default, extend `MeetingSearchMimic` with nearby results, and add `aGeoPoint` and `aNearbyBmltResponse`; verify with mimic unit tests
- [ ] 2.3 Give `BmltServerMimic` a radius response slot keyed by `geo_width_km`, with held responses; verify with a mimic unit test that serves different rows for 15 and 30 km and releases them out of order

## 3. Acceptance tests first (red)

- [ ] 3.1 Extend `pumpApp` with the `GeolocationMimic` override and the `TestTime` handle the nearby scenarios need; verify that the existing acceptance suite still passes
- [ ] 3.2 Write one `testWidgets` per scenario of the delta requirements "Meetings nearby", "Location acquisition and timeouts", "Nearby results states" and "Location permission" (except "Approximate location is accepted", which is covered in 4.2), plus "Empty object means no meetings", "Radius query carries the exact parameters" and "Loader text while searching", in `app/test_acceptance/meetings_search/nearby/`; verify that they fail because the feature is missing, not because of harness errors

## 4. Adapters (D4, D5)

- [ ] 4.1 Pin `geolocator` 14.0.3, `geolocator_platform_interface` 4.3.0 and `geolocator_android` 5.0.3; create `packages/adapters/adapter_geolocation` (`version: 0.0.0`, in the workspace and in `coverage.yaml` under the adapter default); verify with `./bin/na check deps` and that `pubspec.lock` resolves no geolocator package newer than these pins
- [ ] 4.2 Implement `GeolocatorLocation` and `geolocationOverrides` with the permission mapping, the services check, medium accuracy and the exception mapping; verify with adapter unit tests against `GeolocatorPlatformMimic`, covering every mapping row, services off, a thrown error, and a `whileInUse` permission with a reduced-accuracy position ("Approximate location is accepted")
- [ ] 4.3 Add `BmltEndpoints.nearby` and `DioMeetingSearch.nearbyMeetings`; verify with adapter tests against `BmltServerMimic` that assert the exact recorded URI for lat 55.476224, lng 8.4606976, 15 km and for 56.15 / 10.2, plus `{}`, network failure and decode failure

## 5. Nearby controller (D6)

- [ ] 5.1 Implement `NearbyMeetingsController` (radius from `SettingsPort`, locate flow, best origin, generation tickets, slider debounce of 500 ms, retry, dispose cleanup); verify with `TestTime` unit tests for every timing scenario: the 10 s and 45 s timeouts, a late fix, a refusal, services off, relocating, an older result discarded, previous results kept, a failure and retry, and that disposing ends the busy span and ignores a late fix
- [ ] 5.2 Verify with a unit test that moving the slider never calls `SettingsPort.write` and that a new controller starts again from the stored radius

## 6. Design system and shell (D7, D8)

- [ ] 6.1 Add the `footer` slot to `NaPageFrame`, `NaIcons.locate`, and `NaSliderWithEnds` (moved from Settings' radius row); verify with widget tests, and that the Settings goldens are unchanged
- [ ] 6.2 Add `PageFooter` (`NoFooter`, `FooterContent`) to `ShellPage`, update every call site, and map `BusyActivity.locating` to `l10n.locating` in the shell; verify with shell widget tests and the "Locating…" loading-bar unit test
- [ ] 6.3 Add `nearbyRadiusLabel` to both ARB files, change the English `locating` to "Locating…", regenerate with `./bin/na gen l10n`, and correct the `LOCATIONSEARCH`, `NO_LOCATION`, `LOCATING` and `KM` rows in `docs/LEGACY_PARITY.md`; verify with `./bin/na check arb`

## 7. Page and wiring (D7, D9)

- [ ] 7.1 Build `NearbyBody` (the four states, the "Location not set" note) and `NearbyFooter` (button and slider) in `feature_meetings_search`; verify with widget tests for each state and for the slider and button callbacks
- [ ] 7.2 Wire `MenuDestination.nearby` to the page with its footer in `app/lib/app/na_router.dart`, and add `geolocationOverrides(platform: GeolocatorPlatform.instance)` to `platformOverrides()`; verify that the acceptance tests from 3.2 pass with `./bin/na test acceptance`
- [ ] 7.3 Add `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` to `AndroidManifest.xml` and `NSLocationWhenInUseUsageDescription` (legacy text) to `Info.plist`; verify that `./bin/na run android --emulator` shows the system prompt on first opening "Meetings nearby"

## 8. Goldens and accessibility (D10)

- [ ] 8.1 Add goldens and `expectAccessible` for `NaSliderWithEnds`, the footer, the note and every `NearbyBody` state; verify with `./bin/na test widget`

## 9. End to end and definition of done

- [ ] 9.1 Add the Patrol test `app/integration_test/nearby_meetings_test.dart` (open "Meetings nearby", grant the permission with `$.native.grantPermissionWhenInUse()`, expect meeting cards from `BmltServerMimic`); verify with `./bin/na test e2e --device <android emulator>`
- [ ] 9.2 Capture da/en Android screenshots of the nearby page (results, the "Location not set" note, the error state) into `docs/screenshots/meetings-search/`; add iOS screenshots and the iOS permission check to slice 0's open macOS task
- [ ] 9.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check` and confirm every floor is met, including `adapter_geolocation`

## Workflow follow-up

- On archive, add to "Intentional deltas from the legacy app" in `openspec/specs/meetings-search/spec.md`:
  - the unreachable "Location not set" text is now shown
  - an older search result can no longer replace a newer one
  - a failed nearby search is retryable instead of leaving the loader on an empty page
- Archive with `/opsx:archive slice-2-location-search` after the PR is merged.
