# Spec Delta

## MODIFIED Requirements

### Requirement: Meeting details modal

The meeting details modal (title "Meeting Details" (Mødedetaljer), "Close"
button) SHALL fetch the meetings by id from Tomato
(`<tomato>?switcher=GetSearchResults&meeting_ids[]=<id>` repeated per id; the
brackets travel percent-encoded as `%5B%5D`, which BMLT decodes) and
render one meeting card per result, in the returned order. It is opened from
the map (one or several co-located ids). While loading it shows a spinner and
"Finding meetings…" in the loading bar; a failed request shows "The meetings
could not be loaded" with "Try again".

#### Scenario: Modal shows all co-located meetings

- **WHEN** the modal opens for ids `123` and `456`
- **THEN** two meeting cards are shown in the returned order

#### Scenario: By-id query carries every id

- **WHEN** the modal opens for ids `123` and `456`
- **THEN** the request is `<tomato>?switcher=GetSearchResults&meeting_ids%5B%5D=123&meeting_ids%5B%5D=456`

#### Scenario: Close dismisses the modal

- **WHEN** the user taps "Close"
- **THEN** the modal is dismissed and the map is unchanged

#### Scenario: Failed details can be retried

- **WHEN** the by-id request fails and the user taps "Try again" and it succeeds
- **THEN** the meeting cards are shown
