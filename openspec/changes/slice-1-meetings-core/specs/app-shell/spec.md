# Spec Delta

## MODIFIED Requirements

### Requirement: Routes

The app SHALL register these routes: `/` (redirects to `/home`), `/home`,
`/map-search`, `/location-search`, `/listfull`, `/listfull/<municipality>`,
`/jft`, `/cleantime-counter`, `/events`, `/audiobooks`, `/basic-text`,
`/how-and-why`, `/step-working-guides`, `/speaks`, `/grc`, `/settings`,
`/contact`. `<municipality>` is the URL-encoded municipality name as shown in
the municipality list. The side menu marks "Meetings" as the current entry on
both `/listfull` routes. Meeting details open as a modal route on top of the
current page, not as a menu destination.

#### Scenario: Root redirects to home

- **WHEN** the app starts
- **THEN** the Home page is shown at `/home`

#### Scenario: Unknown route falls back to home

- **WHEN** navigation to an unregistered path is requested
- **THEN** the app shows the Home page

#### Scenario: Municipality sub-page keeps the menu entry

- **WHEN** the user is on `/listfull/K%C3%B8benhavn` and opens the menu
- **THEN** "Meetings" is the selected entry and the header reads "København"

### Requirement: Hardware back button

On Android the system back gesture SHALL behave as follows, first match wins:
an open modal or popover is closed; a sub-page returns to its parent (book
chapter page → `/audiobooks`, municipality meetings → the municipality list);
any other page navigates to `/home`; on `/home` the app is sent to the
background.

#### Scenario: Back from a page returns home

- **WHEN** the user is on `/settings` and presses the system back button
- **THEN** the app navigates to `/home`

#### Scenario: Back from a book page returns to the audiobooks list

- **WHEN** the user is on `/basic-text` and presses the system back button
- **THEN** the app navigates to `/audiobooks`

#### Scenario: Back on home leaves the app

- **WHEN** the user is on `/home` with no modal open and presses the system back button
- **THEN** the app moves to the background and is not closed

#### Scenario: Back from municipality meetings returns to the list

- **WHEN** the user is on `/listfull/Aarhus` and presses the system back button
- **THEN** the app navigates to `/listfull`

#### Scenario: Back closes the formats popover first

- **WHEN** the formats popover is open on `/listfull/Aarhus` and the user presses the system back button
- **THEN** the popover closes and the "Aarhus" meetings stay visible
