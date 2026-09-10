# Cleantime Specification

## Purpose

The Cleantime calculator lets members keep one or more named clean dates, see
their clean time broken down three ways, celebrate anniversaries with the
matching key tag, and get a local notification on every upcoming anniversary.
Home shows a card per profile.

> Source: App/src/app/pages/cleantime-counter/cleantime-counter.page.{ts,html}, App/src/app/providers/cleantime.service.ts, App/src/app/providers/notification.service.ts, App/src/app/pages/home/home.page.{ts,html} (legacy)

## Requirements

### Requirement: Profiles

The app SHALL keep a list of cleantime profiles `{name, cleandate}` under the
setting `cleanDateProfiles` and the index of the active profile under
`activeProfile`. When the list is empty on opening the page a default profile
named "Profile 1" (Profil 1) with today's date is created and made active.
There is always at least one profile. Profiles and the active index are
persisted whenever they change.

#### Scenario: First open creates the default profile

- **WHEN** the Cleantime page opens with no stored profiles
- **THEN** one profile "Profile 1" with today's date exists and is active

#### Scenario: Active profile is restored

- **WHEN** two profiles exist and `activeProfile` is `1`
- **THEN** the page opens with the second profile selected

### Requirement: Profile management

The header SHALL show a profile selector (dialog with "Select" (Vælg) and
"Cancel" (Afbryd)) and three buttons: add (green), rename (blue), delete (red).
Add opens a dialog with a text field (placeholder "New profile name here" (Ny
profilnavn her)) and the buttons "Cancel" (Afbryd) / "Create" (Opret); the new
profile gets today's date and becomes active. Rename opens "Rename profile"
(Omdøb profil) with the current name as placeholder and "Cancel" / "Rename"
(Omdøb). Delete opens "Are you sure?" (Er du sikker?) with "Cancel" / "Delete"
(Slet); on confirm the active profile is removed, the first profile becomes
active, and a default profile is created if none is left.

#### Scenario: Add makes the new profile active

- **WHEN** the user adds a profile named "Anna"
- **THEN** "Anna" is appended with today's clean date and selected

#### Scenario: Rename keeps the date

- **WHEN** the user renames the active profile to "Bo"
- **THEN** the name is "Bo" and the clean date is unchanged

#### Scenario: Deleting the last profile recreates the default

- **WHEN** only one profile exists and the user confirms delete
- **THEN** a fresh "Profile 1" with today's date is the only profile

### Requirement: Clean date picker

The page SHALL show "First clean day" (Første clean dag) with a date picker
displaying `DD MMM YYYY` in the app language, buttons "Cancel" (Annuller) /
"OK", and a maximum of today. Changing the date recalculates everything and
persists the profile. The date is stored as a calendar date (no time of day).

#### Scenario: Future dates are not selectable

- **WHEN** the picker is open
- **THEN** dates after today are disabled

#### Scenario: Changing the date recalculates

- **WHEN** the user picks 2020-01-15
- **THEN** all clean-time cards update and `cleanDateProfiles` is persisted

### Requirement: Clean time breakdowns

The app SHALL compute from the clean date to today (both as calendar dates in
the device time zone):

1. years / months / days: `years = floor(diffYears)`, then `months = floor(diffMonths(cleanDate + years))`, then `days = floor(diffDays(cleanDate + years + months))`;
2. months / days: `months = floor(diffMonths)`, `days = floor(diffDays(cleanDate + months))`;
3. days: `floor(diffDays)`.

They are shown as three groups of cards separated by "- OR -" (- ELLER -) rows:
"Clean years", "Clean months", "Clean days" (group 1), "Clean months", "Clean
days" (group 2), "Clean days" (group 3). Each card reads "<n> <unit>" with the
unit singular when n = 1 ("year"/"years", "month"/"months", "day"/"days").

#### Scenario: Breakdown for a known date

- **WHEN** the clean date is 2023-01-31 and today is 2026-03-01
- **THEN** group 1 reads 3 years, 1 month, 1 day; group 2 reads 37 months, 1 day; group 3 reads 1125 days

#### Scenario: Singular units

- **WHEN** the clean date is yesterday
- **THEN** the days card reads "1 day"

### Requirement: Unit order setting

When `cleanTimeUnitSort` is `dmy` the cards inside each group SHALL be shown in
reverse order (days, months, years); when `ymd` (default) in the order above.

#### Scenario: Days first

- **WHEN** `cleanTimeUnitSort` is `dmy`
- **THEN** group 1 shows Clean days, Clean months, Clean years in that order

### Requirement: Anniversary detection and key tag

The app SHALL recognise these anniversaries, evaluated in this order with the
first match winning, using `days = floor(diffDays)`, `monthsPrecise =
diffMonths` (fractional), `yearsPrecise = diffYears` (fractional) and `years =
floor(yearsPrecise)`:

| Name | Condition | Shown as |
|---|---|---|
| 1-day | days == 1 | "1 day" |
| 30-days | days == 30 | "30 days" |
| 60-days | days == 60 | "60 days" |
| 90-days | days == 90 | "90 days" |
| 6-months | monthsPrecise == 6 | "6 months" |
| 9-months | monthsPrecise == 9 | "9 months" |
| 1-year | yearsPrecise == 1 | "1 year" |
| 18-months | monthsPrecise == 18 | "18 months" |
| x-years | yearsPrecise == years and years > 1 | "<years> years" |

On an anniversary a card "Cleanday" (Mærkedag) SHALL show "<n> <unit>" and the
key tag image `assets/keytags/<language>/<name>.png` where `<language>` is `da`
or `en`. On any other day the card is absent.

#### Scenario: One year shows the year tag

- **WHEN** the clean date is exactly one year before today
- **THEN** the "Cleanday" card reads "1 year" and shows `assets/keytags/da/1-year.png` in Danish

#### Scenario: Multi-year anniversary

- **WHEN** the clean date is exactly five years before today
- **THEN** the card reads "5 years" and shows `x-years.png`

#### Scenario: No anniversary

- **WHEN** the clean date is 45 days before today
- **THEN** no "Cleanday" card is shown

### Requirement: Upcoming anniversaries

For a clean date the app SHALL compute the anniversaries falling within a
window from today (inclusive) to today + 2 years (inclusive): the fixed ones by
adding their offsets (1, 30, 60, 90 days; 6, 9, 18 months; 1 year) to the
clean date, and every whole year `n ≥ 1` by adding `n` years until the date
passes the window, skipping a date already produced by a fixed anniversary
(1 year).

#### Scenario: Window for a recent clean date

- **WHEN** the clean date is 10 days ago
- **THEN** the upcoming anniversaries are 30 days, 60 days, 90 days, 6 months, 9 months, 1 year, 18 months and 2 years

#### Scenario: Window for an old clean date

- **WHEN** the clean date is 4 years and 200 days ago
- **THEN** the upcoming anniversaries are 5 years and 6 years only

### Requirement: Anniversary notifications

On opening Home or the Cleantime page the app SHALL cancel all scheduled
anniversary notifications and reschedule one local notification per upcoming
anniversary of every profile at 10:00 local time on the anniversary date, with
the title "Cleanday - <profile name>" (Mærkedag - <name>) and the body
"Congratulations on <n> <unit>" (Tillykke med <n> <unit>). Notification ids are
assigned 1, 2, 3… in profile order then anniversary order. Nothing is scheduled
when there are no anniversaries in the window. The notification permission is
requested the first time a notification would be scheduled.

#### Scenario: Notifications are rescheduled from scratch

- **WHEN** Home opens with two profiles having 8 and 2 upcoming anniversaries
- **THEN** all existing notifications are cancelled and 10 are scheduled with ids 1–10 at 10:00 on their dates

#### Scenario: Notification text is localised

- **WHEN** the app language is `en` and profile "Anna" has a 90-days anniversary
- **THEN** the notification title is "Cleanday - Anna" and the body "Congratulations on 90 days"

#### Scenario: Nothing to schedule

- **WHEN** the only profile has no anniversary within 2 years
- **THEN** existing notifications are cancelled and none are scheduled

### Requirement: Home cleantime cards

Home SHALL show one swipeable card per profile titled "Cleantime" with the
profile name, the years / months / days breakdown ("<y> years, <m> months, <d>
days" with singular forms) and the clean date formatted `dd. MMMM yyyy` in the
app language. Tapping a card opens the Cleantime page.

#### Scenario: Home card content

- **WHEN** profile "Anna" has clean date 2020-05-03 and today is 2026-09-10
- **THEN** the card shows "Anna", "6 years, 4 months, 7 days" and the date "03. maj 2020" in Danish

#### Scenario: Card opens the calculator

- **WHEN** the user taps the cleantime card
- **THEN** the app navigates to `/cleantime-counter`

## Intentional deltas from the legacy app

- Notification title and body were hard-coded Danish ("Mærkedag - ", "Tillyke med " with a typo). They are localised in both languages and spelled correctly.
- The key tag image path was hard-coded to `assets/keytags/da/`; the `en` folder existed but was unused. The image follows the app language.
- The legacy stored `cleandate` as an ISO timestamp with the device offset; the rewrite stores a calendar date (`yyyy-MM-dd`). Migration converts the legacy value (see legacy-migration).
- The legacy dialog texts "Vælg"/"Afbryd"/"Annuller"/"Ok" on the profile selector and date picker were hard-coded; they are localised.
- Legacy month names in the date picker were a hard-coded Danish array; the picker uses the locale.
- Legacy triggered `setTimeout` re-renders to refresh selectors; not applicable.
