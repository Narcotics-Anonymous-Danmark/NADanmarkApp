# Slice 2: meetings nearby

## Why

"Meetings nearby" is the quickest way to find a meeting from where the user
is standing. It is the second meeting feature in the porting order because it
reuses slice 1's meeting list, card and formats unchanged. It adds the first
native permission flow (device location) and the Tomato radius query, which
the map (slice 7) will reuse.

## What Changes

- **Device location** (`GeolocationPort`, new `adapter_geolocation` on
  `geolocator`). It reports the permission state, asks for when-in-use
  permission and returns one position fix. Approximate location is enough.
- **Locating rules**: "Locating…" in the loading bar, a 10 s timeout when
  permission is already granted and 45 s when the prompt may be shown.
  Without a position the search runs on the current best coordinates (the
  default lat `55.476224`, lng `8.4606976` when there are none). A position
  that arrives after the timeout runs the search again. A denied permission
  or disabled location services search at once, without waiting.
- **Tomato radius query** in `adapter_bmlt`, with the exact legacy query
  string and `{}` read as "no results".
- **`/location-search` page** (`feature_meetings_search`). It shows the
  results in the shared meeting list. The footer holds a "Meetings nearby"
  button that locates again and a 5–50 km radius slider. The slider starts at
  the `searchRange` setting and searches again 500 ms after the last change,
  with the same coordinates. The page shows "Nothing found" for no results,
  and an error with "Try again" when the search fails. A newer search always
  wins over an older one.
- **"Location not set" note** (Placeringen er ikke indstillet) above the
  results when the search used the default coordinates.
- **Native permission configuration**: Android `ACCESS_COARSE_LOCATION` and
  `ACCESS_FINE_LOCATION`. iOS `NSLocationWhenInUseUsageDescription` with the
  legacy purpose text.
- **Loading bar** gains the "Locating…" activity. The English text changes
  from "Locating..." to "Locating…", matching "Finding meetings…".

Legacy behaviour not reproduced:
- The "Location not set" text existed but was never reached. The page showed
  meetings around Esbjerg with no hint that the position was unknown.
- A result from an older request could replace a newer one, for example when
  the slider moved while a search was still pending.
- A failed search left the loader on an empty page with no way to retry.
- The page radius fell back to 25 km instead of the 15 km setting default.
  The main spec already records this.

## Non-goals

- Map, map pins, the details modal and meetings by id. These are slice 7.
- Background location, location streams or the my-location dot.
- Persisting the page slider. It changes only this page's search, as in the
  legacy app. "Default search range" in Settings stays the only stored value.
- Localising the iOS permission purpose text. It stays the legacy English
  text, and Danish can follow with slice 0's open macOS task.
- Reverse geocoding or showing an address.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `meetings-search`:
  - "Meetings nearby" gets the slider rules (the setting as the start value,
    not persisted) and the rule that the newest search wins.
  - "Location acquisition and timeouts" gets the denied-permission and
    location-services-off cases, and "Meetings nearby" relocates while
    keeping the best coordinates.
  - New requirement "Nearby results states": empty, failure with retry, and
    the "Location not set" note.
  - New requirement "Location permission": when-in-use only, approximate
    location accepted, the purpose text.

## Impact

- **New package:** `packages/adapters/adapter_geolocation` (`geolocator`
  14.0.3, pinned).
- **Extended packages:**
  - `na_kernel`: location permission, position fix, search origin, default
    coordinates, `BusyActivity.locating`
  - `na_ports`: `GeolocationPort`, `MeetingSearchPort.nearbyMeetings`
  - `adapter_bmlt`: radius endpoint and query
  - `na_testing`: `GeolocationMimic`, radius support in `BmltServerMimic`,
    builders
  - `feature_meetings_search`: nearby controller and page body
  - `feature_shell`: "Locating…" text, page footer slot
  - `na_l10n`: the slider's accessible label, "…" in `locating`
  - `app`: route body, production overrides, acceptance tests, a Patrol test
    that grants the permission
- **Native:** `AndroidManifest.xml` location permissions, `Info.plist`
  purpose text.
- **Configuration:** `coverage.yaml` floor for `adapter_geolocation` (the
  adapter default, 80 %), `docs/LEGACY_PARITY.md` key rows aligned with the
  ARB names actually used.
