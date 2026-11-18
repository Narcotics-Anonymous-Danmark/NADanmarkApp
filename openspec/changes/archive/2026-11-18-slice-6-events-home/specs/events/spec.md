# Spec Delta

## MODIFIED Requirements

### Requirement: Calendar feed

The app SHALL fetch
`<NA_API_BASE_URL>/wp-json/wp/v2/calendar?category-slug=bedringsarrangement`
(default base `https://www.nadanmark.dk`) with the headers `Content-Type:
application/json` and `Authorization: Basic <base64(NA_API_BASIC_AUTH)>`
(left out when the setting is empty). The response is a JSON array of events
with at least `event_name`, `event_start_date` (`yyyy-MM-dd`),
`event_start_time` (`HH:mm:ss`, may be empty), `location_town`, `thumbnail`
(URL, may be empty) and `url`. Events whose start date is not a valid
`yyyy-MM-dd` date or whose `url` is not an absolute http(s) URL are skipped;
the others keep feed order. The list is kept in memory for the app session
and fetched once per session, shared by Home and the Events page.

#### Scenario: Request carries basic auth

- **WHEN** events are loaded with `NA_API_BASIC_AUTH` = `user:pass`
- **THEN** the request goes to `https://www.nadanmark.dk/wp-json/wp/v2/calendar?category-slug=bedringsarrangement` with `Authorization: Basic dXNlcjpwYXNz`

#### Scenario: Second page visit uses the cached list

- **WHEN** the Events page is opened twice in one session
- **THEN** only one request is made

#### Scenario: Malformed events are skipped

- **WHEN** the feed returns three events and the second has `event_start_date` `soon`
- **THEN** the page lists the first and third events

### Requirement: Events page list

The Events page (title "Events" (Arrangementer)) SHALL list every event in feed
order as a row with: the thumbnail (or the placeholder image
`na-logo-placeholder.png` when empty or not loadable), the event name, a
calendar line "<dd. MMM yyyy>[ <HH:mm>]" in the app language (time shown only
when `event_start_time` is non-empty), and a location line with
`location_town`. While fetching, the page shows placeholder rows and the
loading bar shows "Loading events…" (Henter arrangementer …). When the feed is
empty the page shows "No upcoming events" (Ingen kommende arrangementer).

#### Scenario: Row with time

- **WHEN** an event has `event_start_date` `2026-10-03` and `event_start_time` `19:30:00`
- **THEN** the row reads "03. okt. 2026 19:30" in Danish

#### Scenario: Row without time or thumbnail

- **WHEN** an event has empty `event_start_time` and empty `thumbnail`
- **THEN** the row shows the placeholder image and the date without a time

#### Scenario: Loading bar while fetching

- **WHEN** the Events page is opened and the feed has not answered yet
- **THEN** the loading bar reads "Loading events…"
- **AND** it hides when the feed answers

#### Scenario: Empty feed

- **WHEN** the feed returns an empty array
- **THEN** the page shows "No upcoming events"

### Requirement: Open event

Tapping a row SHALL open the event's `url` in the system in-app browser
(Custom Tabs on Android, `SFSafariViewController` on iOS).

#### Scenario: Tap opens the event page

- **WHEN** the user taps an event with url `https://nadanmark.dk/event/x`
- **THEN** that URL opens in the in-app browser

### Requirement: Home preview

Home SHALL show a swipeable card set with the first three events from the
feed, each card titled "Events" and rendered like an Events row. Tapping a
card opens `/events`. The set is absent while loading, after a failure and
when there are no events.

#### Scenario: First three events

- **WHEN** the feed returns five events
- **THEN** Home shows cards for events 1, 2 and 3 in feed order

#### Scenario: Card opens the Events page

- **WHEN** the user taps an event card
- **THEN** the app navigates to `/events`

#### Scenario: No events on Home

- **WHEN** the feed returns an empty array
- **THEN** Home shows no event cards

### Requirement: Failure handling

When the feed cannot be loaded the Events page SHALL show "Could not load the
events" (Kunne ikke hente arrangementer) with a "Try again" (Prøv igen)
button, and Home SHALL omit the event cards. No error dialog is shown.

#### Scenario: Offline events page

- **WHEN** the request fails
- **THEN** the page shows "Could not load the events" and "Try again"
- **AND** tapping "Try again" repeats the request

#### Scenario: Offline Home

- **WHEN** the request fails
- **THEN** Home shows the welcome, the cleantime cards and the Just for today card without event cards

## Workflow follow-up

On archive, add to "Intentional deltas from the legacy app":
- Events with an invalid start date or page URL are skipped instead of
  rendering broken rows; an empty feed shows "No upcoming events".
- The event page opens in the system in-app browser, which shows the address;
  the legacy Cordova window hid it.

and replace the delta "Legacy had no failure state …" with: "Legacy had no
failure or empty state (the loader never dismissed on error). Both are added,
with a retry."
