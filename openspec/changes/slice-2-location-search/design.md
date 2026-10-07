# Design

## Context

Slices 0 and 1 provide everything this page shows:
- `MeetingList`, `MeetingCard`, formats and `MeetingsLoadFailed` /
  `NothingFound` in `feature_meetings` and `feature_meetings_search`
- `BusyTracker` and the `BusyStarted` / `BusyEnded` events that drive the
  shell's loading bar (the most recently started activity sets the text)
- `NaSlider` (with `onChanged` / `onChangeEnd`) and the end-label row used by
  Settings
- `Scheduler` / `Clock` with `TestTime` fakes, `TestContainer`, `pumpApp`,
  `BmltServerMimic`
- `SettingsPort` in `na_ports`, holding `searchRadius` as `Km`

What is missing:
- Any device-location code.
- The radius query: `MeetingSearchPort` has only the two Denmark queries.
- A footer slot on `ShellPage` / `NaPageFrame`.
- `BusyActivity.locating`.

Constraints:
- `LayerRules`: `feature_meetings_search` may import `feature_meetings`, but
  not `feature_settings`. The page therefore reads the radius through
  `SettingsPort`, not `currentSettingsProvider`.
- The locating timeout is not the same as "give up on the position". A
  position that arrives after the timeout must still be used (spec "Late
  position triggers a second search"). The timeout therefore cannot live in
  the adapter or in `geolocator`'s `timeLimit`.
- The map (slice 7) needs the same port, with a different rule: no prompt
  without permission. Checking and requesting permission must therefore be
  separate calls.

See `proposal.md` for scope and `specs/meetings-search/spec.md` for behaviour.

## Goals / Non-Goals

**Goals:**
- Keep the whole locate/search timing in one controller driven by
  `Scheduler`, so every timing scenario is a deterministic `TestTime` test.
- Exercise the adapter against a mimic of the platform plugin, and the page
  against a port mimic, the same way slice 1 did for BMLT.

**Non-Goals:**
- A reusable "locate with timeout" use case for the map. Slice 7 has
  different rules and can extract one when there is a second user.
- A location stream or continuous updates.

## Decisions

### D1 Packages

- `na_ports`: `GeolocationPort`, plus `nearbyMeetings` on
  `MeetingSearchPort`.
- `adapter_geolocation` (new): `GeolocatorLocation implements
  GeolocationPort` and `geolocationOverrides(platform: ...)`.
- `feature_meetings_search`: `NearbyMeetingsController` and `NearbyBody` /
  `NearbyFooter`. D1 of slice 1 already planned for the nearby page to join
  this package.
- `app`: the route body for `MenuDestination.nearby`, and the override in
  `platformOverrides()`.

Alternative: `feature_location_search` as in the original plan. Rejected for
the same reason as `feature_listfull` in slice 1: the capability-named package
already exists and `LayerRules` knows it.

### D2 Kernel types

In `na_kernel/lib/src/location/`:

```dart
enum LocationAccess { granted, askable, refused }

sealed class PositionFix {}
final class Located extends PositionFix { final GeoPoint point; }
final class ServicesOff extends PositionFix {}
final class AccessRefused extends PositionFix {}
final class NoFix extends PositionFix {}

sealed class SearchOrigin {}
final class DevicePosition extends SearchOrigin { final GeoPoint point; }
final class DefaultPosition extends SearchOrigin {}
```

`GeoPoint.searchFallback` is lat `55.476224`, lng `8.4606976`.
`SearchOrigin.point` resolves `DefaultPosition` to it. `BusyActivity` gains
`locating`.

The named enum and the sealed classes follow the no-bool / no-null rules.
`SearchOrigin` exists because the page has to tell "searched on the default"
apart from "searched on a real position that happens to be Esbjerg" (the
"Location not set" note).

### D3 GeolocationPort

```dart
abstract interface class GeolocationPort {
  Future<LocationAccess> access();
  Future<LocationAccess> requestAccess();
  Future<PositionFix> currentPosition();
}
```

The port never times out. The caller owns the deadline. `requestAccess()`
returns `refused` when the user says no, even where Android would allow
asking again. That way, one refusal ends the current locate.

### D4 adapter_geolocation

- **Wrapped plugin:** `GeolocatorLocation` wraps an injected
  `GeolocatorPlatform`. Production passes `GeolocatorPlatform.instance`.
- **Mapping:**
  - `whileInUse` / `always` → `granted`
  - `denied` / `unableToDetermine` → `askable`
  - `deniedForever` → `refused`
- **Position:** `currentPosition()` first checks `isLocationServiceEnabled`
  (→ `ServicesOff`). It then calls `getCurrentPosition` with
  `LocationSettings(accuracy: LocationAccuracy.medium)` and no `timeLimit`.
  `PermissionDeniedException` maps to `AccessRefused`,
  `LocationServiceDisabledException` to `ServicesOff`, and any other error to
  `NoFix`.
- **Accuracy:** medium is enough for a radius search of at least 5 km. It
  uses network location and returns faster indoors. It also works when the
  user grants only approximate location on Android 12+.
- **Tests:** the adapter tests use a `GeolocatorPlatformMimic` that
  implements `GeolocatorPlatform`. It scripts the permission answers,
  services on/off, a position, or an exception.
- **Pins:** `geolocator` 14.0.3. The adapter imports
  `geolocator_platform_interface` directly, pinned to 4.3.0, and pins
  `geolocator_android` 5.0.3. That keeps the lockfile off the releases
  published in the last two weeks; a later commit can upgrade them on
  purpose.

Alternative: `permission_handler` for the permission part. Rejected because
geolocator already covers both checking and requesting, and one plugin means
one native surface.

### D5 Radius query

`BmltEndpoints.nearby(centre:, radius:)` builds the exact spec string.
Coordinates use Dart's shortest round-trip `double.toString()`
(`8.4606976`, `10.2`) and are never rounded, matching the legacy
string concatenation. `DioMeetingSearch.nearbyMeetings` reuses `BmltJson` and
`BmltMapper.meetings`, so `{}` becomes an empty list. `BmltServerMimic`
already serves by `switcher` and records URIs. It gains a radius response
slot so tests can serve different rows per `geo_width_km` (needed for "Older
result is discarded").

### D6 NearbyMeetingsController

This is an `autoDispose` `Notifier<NearbyState>` in `feature_meetings_search`.

```dart
final class NearbyState {
  final Km radius;          // what the slider shows
  final NearbyResults results;
}
sealed class NearbyResults {}
final class AwaitingFirstResult extends NearbyResults {}
final class Shown extends NearbyResults { meetings, origin }
final class SearchFailed extends NearbyResults {}
```

**Build.** `build()` returns `AwaitingFirstResult` with the fallback radius.
In a microtask it reads `SettingsPort.read()`, sets the radius and starts
`_locate()`. The radius is read once per page visit, so changes on the page
are never written back, and the next visit starts from the setting again.

**Locate**, one run per call:
1. Open a `BusySpan(locating)`. This is a new `BusyTracker.begin()` that
   returns a handle whose `end()` is idempotent, because locating ends either
   on the fix or on the timeout, whichever comes first.
2. `access()`. The timeout is 10 s if `granted`, else 45 s. Start
   `Scheduler.after(timeout, onTimeout)` before any prompt, as the legacy
   app did.
3. If the result is not `granted`, call `requestAccess()`. If the answer is
   `refused`, cancel the timer, end the span and search at once on the best
   origin.
4. Call `currentPosition()`:
   - `Located` before the timeout: cancel the timer, end the span, set
     `best = DevicePosition` and search.
   - `Located` after the timeout: set `best` and search again (the late
     position).
   - Anything else before the timeout: cancel the timer, end the span and
     search on `best`.
   - Anything else after the timeout: ignore it.
5. `onTimeout`: end the span and search on `best`.

**Best origin.** `best` starts as `DefaultPosition`. Later locates only
replace it with a new `DevicePosition`, so relocating keeps the last real
position.

**Search.** Each search takes a ticket from a monotonically increasing
generation counter. It runs under `BusyTracker.track(findingMeetings)`. A
result is applied only if its ticket is still the latest and `ref.mounted`.
Otherwise it is dropped ("Older result is discarded"). Results are not
cleared while a search runs ("Previous results stay while searching
again"). A failure sets `SearchFailed`. `retry()` sets
`AwaitingFirstResult` and searches the same origin and radius.

**Slider.** `onChanged` updates `radius` at once and calls a
`Scheduler.debounce(500 ms)` debouncer, which searches on `best`. This
happens even while a locate is running; the generation rule keeps only the
newest result. `onChangeEnd` does nothing extra.

**Dispose.** `ref.onDispose` cancels the timer and the debouncer and ends any
open span, so leaving the page never leaves the loading bar on. A late fix
after dispose is ignored through `ref.mounted`.

Alternative: model the timing as a `Stream` pipeline (`timeout` + `merge`).
Rejected because `Stream.timeout` uses real timers, not `Scheduler`, and the
"late fix after timeout" rule is clearer as explicit steps.

### D7 Page layout

- **Footer slot.** `NaPageFrame` gains a `footer` slot drawn between the body
  and the bottom inset, so it sits above the docked player.
- **Shell side.** `ShellPage` gains `footer: PageFooter`, with
  `sealed class PageFooter { NoFooter() | FooterContent(child) }`, following
  the existing `PageBack` pattern. Every current call site passes
  `NoFooter()`.
- **Footer content.** `NearbyFooter` holds an `NaButton` ("Meetings nearby",
  new `NaIcons.locate`) and the slider.
- **Shared slider row.** Settings' slider-with-end-labels row moves into
  `na_design` as `NaSliderWithEnds`, so both pages share it. Settings goldens
  must stay byte-identical, which proves the move changed nothing.
- **Body.** `NearbyBody` switches on `NearbyResults`:
  - `AwaitingFirstResult` → empty
  - `SearchFailed` → `MeetingsLoadFailed`
  - `Shown` with no meetings → `NothingFound`
  - `Shown` → the `NaNote` "Location not set" when the origin is
    `DefaultPosition`, then `MeetingList` (list key `nearby`)

### D8 Loading bar

The shell maps `BusyActivity.locating` to `l10n.locating`. No change to the
counting logic is needed. Because the most recently started activity sets the
text, the bar reads "Locating…" and then "Finding meetings…", and never shows
twice.

### D9 Native configuration

- **Android:** `AndroidManifest.xml` adds `ACCESS_COARSE_LOCATION` and
  `ACCESS_FINE_LOCATION`. Both are needed so Android 12+ offers the
  precise / approximate choice.
- **iOS:** `Info.plist` adds `NSLocationWhenInUseUsageDescription` with the
  legacy text. There is no `Always` key and no background mode. The iOS build
  is checked under slice 0's open macOS task.

### D10 Tests

- **`na_testing`:**
  - `GeolocationMimic` scripts `access`, the answer to `requestAccess`, and a
    `PositionFix` delivered after a `TestTime` delay (or never). It records
    the number of calls.
  - `TestContainer` binds it by default with `granted` and an immediate
    `Located(aGeoPoint())`.
  - Builders: `aGeoPoint`, `aNearbyBmltResponse`.
- **Unit:** a controller test per spec scenario, driven by `TestTime`, plus
  adapter tests against `GeolocatorPlatformMimic` and `BmltServerMimic`.
- **Acceptance:** one `testWidgets` per scenario in
  `app/test_acceptance/meetings_search/nearby/`.
  - "Permission is not requested elsewhere" asserts zero `access` and
    `requestAccess` calls after visiting the other pages.
  - "Position is not persisted" asserts that no `KeyValueStoreMimic` value
    contains the coordinates.
  - "Approximate location is accepted" is covered at the adapter level, as a
    `whileInUse` permission with a low-accuracy position. The page cannot
    tell the two apart, which is the point of the scenario.
- **Patrol:** `app/integration_test/nearby_meetings_test.dart` opens "Meetings
  nearby", grants the permission with
  `$.native.grantPermissionWhenInUse()`, and expects meeting cards from
  `BmltServerMimic`. The mimic answers any coordinates, so the emulator's
  position does not matter.
- **Goldens + `expectAccessible`:** footer, note, and every `NearbyBody`
  state.

### D11 Localisation

- New key `nearbyRadiusLabel`: "Search radius" (Søgeradius), the slider's
  accessible label.
- `locating` (en) becomes "Locating…". The Danish "Finder position …" is
  unchanged.
- Reused keys: `locationsearch`, `noLocation`, `kmValue`, `nothingFound`,
  `meetingsLoadFailed`, `tryAgain`.
- `docs/LEGACY_PARITY.md` rows `LOCATIONSEARCH`, `NO_LOCATION`, `LOCATING`
  and `KM` are corrected to the ARB names actually used.

## Risks / Trade-offs

- **[Risk]** `getCurrentPosition` may never complete on some devices (no
  Play Services, emulator without a fix). → The controller's timeout always
  searches. The pending future is ignored after dispose.
- **[Risk]** CI emulators have no GPS fix, so the Patrol test could wait
  10 s. → The test waits for cards with a generous timeout. The mimic ignores
  coordinates.
- **[Risk]** `geolocator` 14.1.x and `geolocator_android` 5.1.x were released
  days ago, and a caret constraint would pull them in. → Exact pins from D4.
  `./bin/na check deps` keeps direct pins exact.
- **[Trade-off]** The page slider is not persisted. That matches the legacy
  app and the spec, but users may expect it to stick. → Recorded in the
  proposal's non-goals. Revisit after parity.
- **[Trade-off]** A slider search during a locate may briefly show results
  around the old origin before the located search replaces them. → This is
  acceptable; the newest search always wins.

## Migration Plan

No data migration: `searchRange` was already imported in slice 0 and the
position is never stored. To roll back, point the `nearby` route body back to
the empty placeholder. The adapter and the permissions are inert without the
page.
