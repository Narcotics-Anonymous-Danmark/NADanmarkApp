# Spec Delta

## MODIFIED Requirements

### Requirement: Profiles

The app SHALL keep a list of cleantime profiles `{name, cleanDate}` under the
setting `cleantimeProfiles` (a JSON list, `cleanDate` as `yyyy-MM-dd`) and the
index of the active profile under `activeCleantimeProfile`. When the list is
empty on opening the page, a default profile named "Profile 1" (Profil 1, in
the app language) with today's date is created and made active. There is
always at least one profile once the page has been opened. Profiles and the
active index are persisted whenever they change. A stored value that cannot
be read counts as "no profiles". A stored active index outside the list is
clamped to it.

#### Scenario: First open creates the default profile

- **WHEN** the Cleantime page opens with no stored profiles
- **THEN** one profile "Profile 1" with today's date exists and is active
- **AND** `cleantimeProfiles` and `activeCleantimeProfile` are persisted

#### Scenario: Active profile is restored

- **WHEN** two profiles exist and `activeCleantimeProfile` is `1`
- **THEN** the page opens with the second profile selected

#### Scenario: Unreadable profiles fall back to the default

- **WHEN** `cleantimeProfiles` holds `"oops"` and the Cleantime page opens
- **THEN** the only profile is "Profile 1" with today's date

#### Scenario: Stored active index is clamped

- **WHEN** two profiles exist and `activeCleantimeProfile` is `7`
- **THEN** the page opens with the second profile selected

### Requirement: Profile management

The header SHALL show the active profile's name as a selector and three
buttons: add (green), rename (blue) and delete (red), each with an accessible
label ("Add profile", "Rename profile", "Delete profile").
- **Selector**: a dialog listing the profile names with "Cancel" (Afbryd).
  Tapping a name selects it.
- **Add**: a dialog with a text field (placeholder "New profile name here" (Ny
  profilnavn her)) and the buttons "Cancel" (Afbryd) / "Create" (Opret). The
  new profile gets today's date and becomes active.
- **Rename**: the dialog "Rename profile" (Omdøb profil), with the current name
  as the field's initial text, and the buttons "Cancel" / "Rename" (Omdøb).
- **Delete**: the dialog "Are you sure?" (Er du sikker?), with "Cancel" /
  "Delete" (Slet). On confirm the active profile is removed and the first
  profile becomes active. A default profile is created if none is left.

Names are trimmed. "Create" and "Rename" are disabled while the trimmed name
is empty. Cancelling any dialog changes nothing.

#### Scenario: Add makes the new profile active

- **WHEN** the user adds a profile named "Anna"
- **THEN** "Anna" is appended with today's clean date and selected

#### Scenario: Rename keeps the date

- **WHEN** the user renames the active profile to "Bo"
- **THEN** the name is "Bo" and the clean date is unchanged

#### Scenario: Deleting the last profile recreates the default

- **WHEN** only one profile exists and the user confirms delete
- **THEN** a fresh "Profile 1" with today's date is the only profile

#### Scenario: Deleting selects the first profile

- **WHEN** profiles "Anna", "Bo" and "Carl" exist, "Carl" is active and the user confirms delete
- **THEN** the profiles are "Anna" and "Bo" and "Anna" is selected

#### Scenario: Selecting a profile from the list

- **WHEN** profiles "Anna" and "Bo" exist, "Anna" is active and the user taps "Bo" in the selector
- **THEN** "Bo" is selected and `activeCleantimeProfile` is `1`

#### Scenario: Blank names cannot be saved

- **WHEN** the add dialog's field holds only spaces
- **THEN** "Create" is disabled

#### Scenario: Cancelling delete keeps the profile

- **WHEN** the user opens the delete dialog and taps "Cancel"
- **THEN** the profiles are unchanged

### Requirement: Clean date picker

The page SHALL show "First clean day" (Første clean dag) with the active
profile's date formatted `dd MMM yyyy` in the app language. Tapping it opens
a wheel picker (day, month, year) with the month names of the app language
and the buttons "Cancel" (Annuller) / "OK". Dates after today cannot be
picked: they are shown dimmed, and a wheel that stops on one snaps back to
today. "OK" changes the clean date, recalculates everything and persists the
profile. The date is stored as a calendar date (no time of day).

#### Scenario: Future dates are not selectable

- **WHEN** today is 2026-09-10 and the user turns the day wheel to 25 September 2026
- **THEN** the picker snaps back to 10 September 2026

#### Scenario: Changing the date recalculates

- **WHEN** the user picks 2020-01-15 and taps "OK"
- **THEN** all clean-time cards update and `cleantimeProfiles` holds `2020-01-15` for the active profile

#### Scenario: Cancelling the picker keeps the date

- **WHEN** the user turns the wheels and taps "Cancel"
- **THEN** the clean date is unchanged

#### Scenario: Date is shown in the app language

- **WHEN** the clean date is 2020-05-03 and the app language is `da`
- **THEN** the picker field reads "03 maj 2020"

### Requirement: Clean time breakdowns

The app SHALL compute from the clean date to today, both as calendar dates in
the device time zone:

1. years / months / days: `years = floor(diffYears)`, then `months = floor(diffMonths(cleanDate + years))`, then `days = floor(diffDays(cleanDate + years + months))`;
2. months / days: `months = floor(diffMonths)`, `days = floor(diffDays(cleanDate + months))`;
3. days: `floor(diffDays)`.

Adding months clamps the day to the last day of the target month.
`diffMonths(a, b)` is the largest `n` with `a + n months ≤ b`. A year is 12
months. These are moment's rules, and they are checked against a fixture
table computed with the legacy code. A clean date after today counts as today.

The breakdowns are shown as three groups of cards separated by "- OR -" (-
ELLER -) rows:
- group 1: "Clean years", "Clean months", "Clean days";
- group 2: "Clean months", "Clean days";
- group 3: "Clean days".

Each card reads "<n> <unit>", with the unit singular when n = 1
("year"/"years", "month"/"months", "day"/"days").

#### Scenario: Breakdown for a known date

- **WHEN** the clean date is 2023-01-31 and today is 2026-03-01
- **THEN** group 1 reads 3 years, 1 month, 1 day; group 2 reads 37 months, 1 day; group 3 reads 1125 days

#### Scenario: Singular units

- **WHEN** the clean date is yesterday
- **THEN** the days card reads "1 day"

#### Scenario: Units return to plural

- **WHEN** the clean date is yesterday and the user then picks a date two days ago
- **THEN** the days card reads "2 days"

#### Scenario: Month-end clean date

- **WHEN** the clean date is 2023-08-31 and today is 2024-02-29
- **THEN** group 1 reads 0 years, 6 months, 0 days

#### Scenario: Clean date after today

- **WHEN** the stored clean date is 2026-09-12 and today is 2026-09-10
- **THEN** every card reads 0

### Requirement: Anniversary detection and key tag

The app SHALL recognise the anniversaries below. They are evaluated in this
order and the first match wins. A month or year anniversary matches when
adding that many months or years (with the clamping above) to the clean date
gives today. `days` is `floor(diffDays)`.

| Name | Condition | Shown as |
|---|---|---|
| 1-day | days == 1 | "1 day" |
| 30-days | days == 30 | "30 days" |
| 60-days | days == 60 | "60 days" |
| 90-days | days == 90 | "90 days" |
| 6-months | cleanDate + 6 months == today | "6 months" |
| 9-months | cleanDate + 9 months == today | "9 months" |
| 1-year | cleanDate + 1 year == today | "1 year" |
| 18-months | cleanDate + 18 months == today | "18 months" |
| x-years | cleanDate + n years == today for some n > 1 | "<n> years" |

On an anniversary a card "Cleanday" (Mærkedag) SHALL show "<n> <unit>" above
the clean-time cards. Below the text it shows the key tag image
`keytags/<language>/<name>.png`, where `<language>` is `da` or `en`. The
image has the accessible label "<n> <unit> key tag" (Nøglering for <n>
<unit>). On any other day the card is absent.

#### Scenario: One year shows the year tag

- **WHEN** the clean date is exactly one year before today and the app language is `da`
- **THEN** the "Cleanday" card reads "1 år" and shows `keytags/da/1-year.png`

#### Scenario: Key tag follows the language

- **WHEN** the clean date is 30 days before today and the app language is `en`
- **THEN** the "Cleanday" card reads "30 days" and shows `keytags/en/30-days.png`

#### Scenario: Multi-year anniversary

- **WHEN** the clean date is exactly five years before today
- **THEN** the card reads "5 years" and shows `x-years.png`

#### Scenario: Month end is not an anniversary a day late

- **WHEN** the clean date is 2023-02-28 and today is 2024-02-29
- **THEN** no "Cleanday" card is shown

#### Scenario: No anniversary

- **WHEN** the clean date is 45 days before today
- **THEN** no "Cleanday" card is shown

### Requirement: Unit order setting

When `cleanTimeUnitSort` is `dmy` the cards inside each group SHALL be shown in
reverse order (days, months, years); when `ymd` (default) in the order above.
A change in Settings applies the next time the page is shown.

#### Scenario: Days first

- **WHEN** `cleanTimeUnitSort` is `dmy`
- **THEN** group 1 shows Clean days, Clean months, Clean years in that order

### Requirement: Anniversary notifications

The app SHALL cancel every scheduled anniversary notification and schedule
them again from scratch:
- when Home or the Cleantime page is shown;
- after any change to the profiles or a clean date;
- after the app language changes.

There is one local notification per upcoming anniversary of every profile, at
10:00 local time on the anniversary date. Its title is "Cleanday - <profile
name>" (Mærkedag - <navn>) and its body "Congratulations on <n> <unit>"
(Tillykke med <n> <unit>).

- **Past instants**: an instant less than one minute after now is skipped.
- **Ordering, cap and ids**: the remaining notifications are sorted by
  instant, then by profile order. At most the first 64 are scheduled (the
  iOS limit), with ids 1, 2, 3… in that order.
- **Nothing to schedule**: when there are no notifications, only the cancel
  happens.
- **Permission**: requested the first time there is at least one notification
  to schedule. When it is refused, nothing is scheduled and the pages work as
  usual.
- **Failure**: a failure of the notification system never blocks the pages.

#### Scenario: Notifications are rescheduled from scratch

- **WHEN** Home opens with two profiles having 8 and 2 upcoming anniversaries after now
- **THEN** all existing notifications are cancelled and 10 are scheduled with ids 1–10 at 10:00 on their dates

#### Scenario: Notification text is localised

- **WHEN** the app language is `en` and profile "Anna" has a 90-days anniversary
- **THEN** the notification title is "Cleanday - Anna" and the body "Congratulations on 90 days"

#### Scenario: Danish notification text

- **WHEN** the app language is `da` and profile "Anna" has a 1-year anniversary
- **THEN** the notification title is "Mærkedag - Anna" and the body "Tillykke med 1 år"

#### Scenario: Nothing to schedule

- **WHEN** the only profile has no anniversary within 2 years
- **THEN** existing notifications are cancelled and none are scheduled
- **AND** no permission is requested

#### Scenario: Passed time today is skipped

- **WHEN** it is 14:00 on 2026-09-10 and the clean date is 2026-08-11 (30 days today)
- **THEN** no notification is scheduled for 2026-09-10 and the first one is "60 days" on 2026-10-10 at 10:00

#### Scenario: Editing a date reschedules

- **WHEN** the user changes the clean date on the Cleantime page
- **THEN** the notifications are cancelled and scheduled again for the new date

#### Scenario: Language change reschedules

- **WHEN** the user switches the language to `en` in Settings
- **THEN** the notifications are scheduled again with English texts

#### Scenario: At most 64 notifications

- **WHEN** ten profiles each have 9 upcoming anniversaries
- **THEN** the 64 earliest are scheduled with ids 1–64

#### Scenario: Permission refused

- **WHEN** a profile has upcoming anniversaries and the user refuses the notification permission
- **THEN** nothing is scheduled and the Cleantime page shows its cards

### Requirement: Home cleantime cards

Home SHALL show, before the JFT card, a horizontally swipeable carousel with
page dots and one card per stored profile. Each card is titled "Cleantime" and
shows:
- the profile name;
- the years / months / days breakdown, "<y> years, <m> months, <d> days" with
  singular forms;
- the clean date formatted `dd. MMMM yyyy` in the app language.

Tapping a card opens the Cleantime page. Without stored profiles there is no
carousel. The page dots are hidden when there is only one profile.

#### Scenario: Home card content

- **WHEN** profile "Anna" has clean date 2020-05-03 and today is 2026-09-10
- **THEN** the card shows "Anna", "6 år, 4 måneder, 7 dage" and the date "03. maj 2020" in Danish

#### Scenario: Card opens the calculator

- **WHEN** the user taps the cleantime card
- **THEN** the app navigates to `/cleantime-counter`

#### Scenario: One card per profile

- **WHEN** profiles "Anna" and "Bo" are stored and the user swipes the carousel left
- **THEN** the card for "Bo" is shown

#### Scenario: No profiles, no carousel

- **WHEN** no profiles are stored and Home opens
- **THEN** no cleantime card is shown and the JFT card is the first card
