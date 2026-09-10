# Events Specification

## Purpose

Events lists upcoming recovery events ("bedringsarrangementer") from the
nadanmark.dk WordPress calendar. Home previews the first three; the Events page
lists them all and opens the event page on tap.

> Source: App/src/app/pages/events/events.page.{ts,html}, App/src/app/providers/event.service.ts, App/src/app/pages/home/home.page.{ts,html} (legacy)

## Requirements

### Requirement: Calendar feed

The app SHALL fetch
`<NA_API_BASE_URL>/wp-json/wp/v2/calendar?category-slug=bedringsarrangement`
(default base `https://www.nadanmark.dk`) with the header `Authorization: Basic
<base64(NA_API_BASIC_AUTH)>` and `Content-Type: application/json`. The
response is a JSON array of events with at least `event_name`,
`event_start_date` (`yyyy-MM-dd`), `event_start_time` (`HH:mm:ss`, may be
empty), `location_town`, `thumbnail` (URL, may be empty) and `url`. The list is
kept in memory for the app session and fetched once per session.

#### Scenario: Request carries basic auth

- **WHEN** events are loaded with `NA_API_BASIC_AUTH` = `user:pass`
- **THEN** the request goes to `https://www.nadanmark.dk/wp-json/wp/v2/calendar?category-slug=bedringsarrangement` with `Authorization: Basic dXNlcjpwYXNz`

#### Scenario: Second page visit uses the cached list

- **WHEN** the Events page is opened twice in one session
- **THEN** only one request is made

### Requirement: Events page list

The Events page (title "Events" (Arrangementer)) SHALL list every event in feed
order as a row with: the thumbnail (or the placeholder image
`assets/img/na-logo-placeholder.png` when empty), the event name, a calendar
line "<dd. MMM yyyy>[ <HH:mm>]" (time shown only when `event_start_time` is
non-empty, first five characters), and a location line with `location_town`.
"Loading events…" is shown in the loading bar while fetching.

#### Scenario: Row with time

- **WHEN** an event has `event_start_date` `2026-10-03` and `event_start_time` `19:30:00`
- **THEN** the row reads "03. okt. 2026 19:30" in Danish

#### Scenario: Row without time or thumbnail

- **WHEN** an event has empty `event_start_time` and empty `thumbnail`
- **THEN** the row shows the placeholder image and the date without a time

### Requirement: Open event

Tapping a row SHALL open the event's `url` in an in-app browser with the
address bar hidden.

#### Scenario: Tap opens the event page

- **WHEN** the user taps an event with url `https://nadanmark.dk/event/x`
- **THEN** that URL opens in the in-app browser

### Requirement: Home preview

Home SHALL show a swipeable card set titled "Events" with the first three events
from the feed, each rendered like an Events row. Tapping a card opens `/events`.
The set is absent when there are no events.

#### Scenario: First three events

- **WHEN** the feed returns five events
- **THEN** Home shows cards for events 1, 2 and 3 in feed order

#### Scenario: Card opens the Events page

- **WHEN** the user taps an event card
- **THEN** the app navigates to `/events`

### Requirement: Failure handling

When the feed cannot be loaded the Events page SHALL show "Could not load the
events" with a "Try again" button, and Home SHALL omit the event cards. No
error dialog is shown.

#### Scenario: Offline events page

- **WHEN** the request fails
- **THEN** the page shows "Could not load the events" and "Try again"
- **AND** tapping "Try again" repeats the request

## Intentional deltas from the legacy app

- The legacy loading text "Loading Events..." was hard-coded English; it is localised.
- Legacy embedded the basic-auth placeholder `btoa("username:password")` in code and patched it at build time; credentials come from `NA_API_BASIC_AUTH` in the environment file.
- Legacy had no failure state (the loader simply never dismissed on error). A failure state and retry are added.
- Legacy rows were `ion-item-sliding` with no options; plain rows.
