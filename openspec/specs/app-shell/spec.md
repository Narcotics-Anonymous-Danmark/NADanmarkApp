# App Shell Specification

## Purpose

The shell is everything around the pages: the side menu, routing, the hardware
back button, the global loading bar, the docked media player and the version
display. It is the first slice ported and the host every other capability
plugs into.

> Source: App/src/app/app.component.{ts,html}, App/src/app/app-routing.module.ts, App/src/app/global-loading/*, App/src/app/providers/loading.service.ts, App/src/theme/variables.scss (legacy)

## Requirements

### Requirement: Side menu entries

The app SHALL show a side menu titled "Menu" with exactly these 12 entries in
this order, each with an icon, and navigating to the given route when tapped:

| # | Label (Danish) | Route | Icon |
|---|---|---|---|
| 1 | Home (Hjem) | `/home` | home |
| 2 | Map (Kort) | `/map-search` | map |
| 3 | Meetings nearby (Møder i nærheden) | `/location-search` | search |
| 4 | Meetings (Mødeliste) | `/listfull` | list |
| 5 | Just for today (Dagens tekst) | `/jft` | albums |
| 6 | Cleantime calculator (Cleantimeberegner) | `/cleantime-counter` | hourglass |
| 7 | Events (Arrangementer) | `/events` | calendar |
| 8 | Audiobooks (Lydbøger) | `/audiobooks` | book |
| 9 | Speaks | `/speaks` | chatbox-ellipses |
| 10 | Group readings (Gruppeoplæsninger) | `/grc` | reader |
| 11 | Settings (Indstillinger) | `/settings` | settings |
| 12 | About (Om denne app / Kontakt) | `/contact` | person |

#### Scenario: Menu lists the twelve entries in legacy order

- **WHEN** the user opens the side menu
- **THEN** the 12 entries above are shown in that order with their icons
- **AND** the labels are in the current app language

#### Scenario: Menu entry navigates and closes the menu

- **WHEN** the user taps "Events" in the side menu
- **THEN** the app navigates to `/events` as a root navigation (no back stack entry to the previous page)
- **AND** the menu closes

### Requirement: Version display in the menu

The app SHALL show "Version: <x.y.z>" as the last row of the side menu, where
`<x.y.z>` is the app version from the build (`pubspec.yaml` version, set by
`./bin/na release version`).

#### Scenario: Version row shows the build version

- **WHEN** the app is built with version `2.0.0` and the user opens the side menu
- **THEN** the last row reads "Version: 2.0.0"

### Requirement: Routes

The app SHALL register these routes: `/` (redirects to `/home`), `/home`,
`/map-search`, `/location-search`, `/listfull`, `/jft`, `/cleantime-counter`,
`/events`, `/audiobooks`, `/basic-text`, `/how-and-why`, `/step-working-guides`,
`/speaks`, `/grc`, `/settings`, `/contact`. Meeting details open as a modal
route on top of the current page, not as a menu destination.

#### Scenario: Root redirects to home

- **WHEN** the app starts
- **THEN** the Home page is shown at `/home`

#### Scenario: Unknown route falls back to home

- **WHEN** navigation to an unregistered path is requested
- **THEN** the app shows the Home page

### Requirement: Page header with menu button

Every top-level page SHALL have a header with a menu button at the start and
the page title in the current language. Sub-pages (book chapter pages, the
meeting list of one municipality) SHALL additionally show a "Back" (Tilbage)
button at the end of the header.

#### Scenario: Header shows title and menu button

- **WHEN** the Settings page is open
- **THEN** the header shows a menu button and the title "Settings"

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

### Requirement: Global loading bar

The app SHALL show one indeterminate progress bar fixed at the top of the
screen while at least one loading operation is active. Loading operations are
reference counted: `present(text)` increments, `dismiss()` decrements and the
bar hides when the count reaches 0. The bar does not block input. The text is
exposed to accessibility as a live status ("Locating…", "Finding meetings…",
"Loading events…").

#### Scenario: Bar stays while any operation is pending

- **WHEN** two loading operations start and one finishes
- **THEN** the loading bar remains visible
- **AND** it hides when the second operation finishes

#### Scenario: Dismiss never goes negative

- **WHEN** `dismiss()` is called with no active operation
- **THEN** the count stays at 0 and the bar stays hidden

### Requirement: Docked media player host

The shell SHALL render the media player once, docked at the bottom above every
page, so playback and its controls survive navigation. While the player is not
idle, pages SHALL add bottom padding equal to the player height so no content is
hidden behind it.

#### Scenario: Player survives navigation

- **WHEN** a speak is playing and the user navigates from `/speaks` to `/home`
- **THEN** playback continues and the docked player is still visible

#### Scenario: Player hidden when idle

- **WHEN** no playlist is active
- **THEN** the docked player is not rendered and pages have no extra bottom padding

### Requirement: Language applied at start

The shell SHALL read the language setting before rendering the first page and
apply it to all texts and to the locale used for dates and numbers. The default
is Danish.

#### Scenario: First start is Danish

- **WHEN** the app starts with no stored language
- **THEN** all texts are Danish and the language setting is persisted as `da`

#### Scenario: Stored English is applied

- **WHEN** the stored language is `en`
- **THEN** the menu and pages render in English on first frame

### Requirement: Visual theme

The app SHALL use these tokens from the legacy theme: page background
`#dddddd`; card background `#eeeeee` with a 1 px `#0a61ad` border; primary
`#0a61ad`; secondary `#0b77d3`; tertiary `#5260ff`; success `#10dc60`;
warning `#ffce00`; danger `#f04141`; dark `#222428`; medium `#989aa2`; light
`#f4f5f8`; weekday colours Sunday `#ff7e79`, Monday `#ffd479`, Tuesday
`#fffc79`, Wednesday `#d4fb79`, Thursday `#73fcd6`, Friday `#73fdff`, Saturday
`#73fa79`; font IBM Plex Sans Medium; Android splash background `#0A61AD`.

#### Scenario: Cards use the legacy palette

- **WHEN** any card is rendered
- **THEN** its background is `#eeeeee` and its border `#0a61ad`

### Requirement: Store identity

The app SHALL be published with application id `dk.nadanmark.app` on Android
and bundle id `dk.nadanmark.ios.app` on iOS, display name "NA Danmark",
minimum Android SDK 26, minimum iOS 16.0.

#### Scenario: Build identifiers

- **WHEN** a release build is produced
- **THEN** the Android package is `dk.nadanmark.app` and the iOS bundle is `dk.nadanmark.ios.app`

## Intentional deltas from the legacy app

- The legacy app subscribed to the back button at priority 0 to go home from every page; sub-page overrides were registered ad hoc. The rule above is explicit and includes closing modals first.
- The legacy menu was an `ion-split-pane` that showed the menu permanently on wide screens. The rewrite uses a drawer at every width.
- Legacy `LOCALE_ID` was pinned to `da-DK` regardless of language. Dates and numbers follow the chosen language (see localisation).
- No web fallback: the legacy code paths for `ionic serve` in a browser are not ported.
