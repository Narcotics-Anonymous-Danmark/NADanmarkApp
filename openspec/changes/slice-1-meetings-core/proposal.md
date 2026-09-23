# Slice 1: meetings core, full meeting list and formats

## Why

Finding meetings is the app's core job and the largest body of pure domain
logic in the legacy app. It has no native risk, so it goes first among the
meeting features. It also builds the shared meeting list, card and formats
code that the nearby search (slice 2) and the map (slice 7) will reuse. The
same slice starts golden tests and accessibility checks across the design
system, as the definition of done requires.

## What Changes

- **BMLT access** (Denmark root): all meetings, the municipality list and
  GetFormats in Danish and English (`lang_enum=da` / `lang_enum=en`), with
  `{}` read as "no results". Base URLs come from
  `BMLT_DENMARK_BASE_URL` / `BMLT_TOMATO_BASE_URL`.
- **Meeting domain**: typed meetings (weekday, start and end time, venue, the
  location lines that are present, contact and transit lines), the
  temporarily-closed and hybrid rules, the directions / virtual-link /
  dial-in actions, municipality normalisation ("Online").
- **Meeting formats**: the definition index in the display language, category
  mapping, resolution by shared id / key / unambiguous lower-case key, Danish
  collation, the 7-day cache with stale fallback and a 60 s retry, stored under
  `meetingFormatsCache`.
- **Shared meeting list** (`feature_meetings` library): weekday sections in
  first-day-of-week order with counts, today highlighted, one section open at
  a time. Also a day selector, a dual-knob hour range (350 ms debounce), the
  meeting card and the formats popover.
- **`/listfull` page** (`feature_meetings_search`): the municipality list
  ("Online" last) and a `/listfull/<municipality>` sub-page with "Back". Also
  loading, empty and error states. The global loading bar reads "Finding
  meetings…".
- **Legacy import** of `meeting_formats_v1` into `meetingFormatsCache`.
- **Design system**: range slider, section header, chip, popover and badge
  components. Goldens and `meetsGuideline` accessibility checks for every
  slice 0 and slice 1 component and page state.
- **Localisation**: new ARB keys (da + en) for the new texts. The legacy Danish
  "Bus"/"Train" labels are corrected, and the English "All days" replaces
  "Weekdays".

Legacy bugs not reproduced:
- The hour filter used the end time.
- The postal code never showed: the legacy app read a field BMLT does not have.
- TC/HY matched as substrings.
- Format names were always Danish: the legacy queries (default and
  `lang_enum=dk`) never return English rows from the Danish server.
- "Online" meetings vanished from the list.
- A failed request left the loader stuck on a blank page.
- A second tap first showed the previous municipality's meetings.
- The Danish Bus/Train labels were wrong.

## Non-goals

- The meeting details modal and the meetings-by-id query are deferred to
  slice 7 (map), their only entry point.
- Nearby search and geolocation are slice 2.
- Map pins and the Tomato radius query are slices 2 and 7.
- Dead virtual-NA code is not ported.
- The `./bin/na check specs` command described in `docs/TESTING.md` is not
  part of this slice.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `meetings-search`:
  - The municipality list gets a sub-route, the "Online" grouping, and empty
    and error states.
  - The card shows the postal code field BMLT actually sends.
  - TC/HY become whole-key matches.
  - The formats cache key becomes `meetingFormatsCache`.
  - Formats are fetched with `lang_enum=da` and `lang_enum=en`, and the
    display row is chosen by `da` / `en`.
- `app-shell`: the route list gains `/listfull/<municipality>`. The back
  button gets scenarios for that sub-page and for the formats popover.
- `legacy-migration`: scenarios for importing and dropping the meeting formats
  cache.
- `localisation`: format names follow the UI language through `lang_enum=da`
  / `lang_enum=en` instead of `dk`.

## Impact

- **New packages:**
  - `packages/features/feature_meetings` (the library)
  - `packages/features/feature_meetings_search`
  - `packages/adapters/adapter_bmlt` (with `dio`)
- **Extended packages:**
  - `na_kernel`: meeting and format domain, boundary readers for BMLT JSON
  - `na_ports`: `MeetingSearchPort`, `MeetingFormatsPort`
  - `na_testing`: builders, `BmltServerMimic`, port mimics, golden and a11y
    helpers
  - `na_design`
  - `na_l10n`
  - `feature_shell`: busy events drive the loading bar; the back rule covers
    the municipality sub-page
  - `feature_legacy_migration`
  - `app`: router, composition, acceptance tests, a Patrol happy path
- **Configuration:**
  - `coverage.yaml` entries for the new packages
  - `docs/LEGACY_PARITY.md` rows aligned with the ARB keys actually used
- **Dependencies:** adds `dio` to `adapter_bmlt` and `na_testing`.
