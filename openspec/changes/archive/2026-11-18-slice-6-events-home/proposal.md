# Slice 6: events and the Home dashboard

## Why

Events ("bedringsarrangementer") are the last WordPress-backed page still
missing, and Home in the Flutter app shows only the cleantime and Just for
today cards. This slice ports the calendar feed and the Events page, and
completes Home with the events cards so the dashboard matches the legacy
page.

## What Changes

- **Calendar types** (`na_kernel`): `CalendarEvent` with its values (name,
  town, start date, start time or none, thumbnail or none, page URL), the
  `CalendarEventDto` wire DTO and `CalendarMapper`.
- **Port**: `EventsFeedPort` with one call for the whole feed.
- **`adapter_wordpress`**: `DioEventsFeed` on the `calendar` endpoint, Basic
  auth from `NA_API_BASIC_AUTH`, `Content-Type: application/json`.
- **`ExternalLinksPort.openInApp`**: opens a page in the system in-app browser
  (Custom Tabs / `SFSafariViewController`) through `url_launcher`.
- **Global loading bar**: `BusyActivity.loadingEvents` with the text "Loading
  events…".
- **`feature_events`** (new):
  - `EventsLoader`: one fetch per session, retry after a failure;
  - `EventTexts`: the calendar line;
  - the Events page with loading rows, error, empty and loaded states;
  - `EventsHomeCards`: the first three events as a carousel on Home.
- **Design system**: `NaThumbnail` (network image with a bundled fallback).
- **App**: the `/events` route renders the page; Home adds the events cards
  after the Just for today card.

Legacy behaviour not reproduced:
- The legacy page had no failure or empty state: the loader stayed forever on
  an error. Both states are added, with "Try again".
- Events without a valid start date or page URL are skipped instead of
  rendering broken rows.
- The in-app browser is the system one (Custom Tabs on Android,
  `SFSafariViewController` on iOS), which shows the page's address. The
  legacy Cordova window hid the address bar.
- "Loading Events..." was hard-coded English; it is localised.

## Non-goals

- Filtering or searching events, event details inside the app, calendar
  export.
- Caching events across app restarts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `events`: optional credentials, skipped malformed rows, empty state,
  system in-app browser, loading rows.
- `app-shell`: the Home dashboard composition (welcome, cleantime cards, Just
  for today, events cards) is specified.

## Impact

- **New packages**: `packages/features/feature_events` with the
  `na-logo-placeholder.png` thumbnail fallback.
- **Extended packages**:
  - `na_kernel`: `calendar/` types, `calendar_wire.dart` DTO and mapper,
    `BusyActivity.loadingEvents`;
  - `na_ports`: `EventsFeedPort`, `ExternalLinksPort.openInApp`;
  - `na_design`: `NaThumbnail`;
  - `na_l10n`: `eventsLoadError`, `eventsLoadErrorBody`, `eventsRetry`,
    `loadingEvents`, `eventsNone`, `eventsNoneBody`, `eventCardPosition`;
  - `na_testing`: calendar routes in `WordPressMimic`, `EventsFeedMimic`,
    event builders and a sample calendar;
  - `adapter_wordpress`, `adapter_links`, `feature_shell`;
  - `app`: route, Home composition, overrides, acceptance tests, a Patrol
    test.
- **Docs**: `docs/LEGACY_PARITY.md` (events keys ported, in-app browser row).
