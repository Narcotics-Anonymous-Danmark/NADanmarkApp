# Settings Specification

## Purpose

The Settings page holds the four user preferences the app has: language, first
day of the week, cleantime unit order and the default search radius. Each is
persisted the moment it changes and read by the feature that needs it.

> Source: App/src/app/pages/settings/settings.page.{ts,html}, App/src/app/app.component.ts (legacy)

## Requirements

### Requirement: Language setting

The app SHALL offer a language selector with "Danish" (Dansk) and "English"
(Engelsk). The default is `da`. Changing it re-renders the whole app in the new
language immediately and persists the choice under the setting key `language`.

#### Scenario: Default language is Danish

- **WHEN** the Settings page opens with no stored language
- **THEN** the selector shows "Danish"

#### Scenario: Switching to English re-renders immediately

- **WHEN** the user selects "English"
- **THEN** the Settings page title becomes "Settings" without leaving the page
- **AND** `language` is persisted as `en`

### Requirement: First day of week setting

The app SHALL offer "First day of week" (Ugen starter med) with the options
"Monday" (`mo`) and "Sunday" (`su`). The default is `mo`. The value is persisted
under `firstday` and used by meeting lists to order weekdays.

#### Scenario: Default is Monday

- **WHEN** the Settings page opens with no stored value
- **THEN** "Monday" is selected

#### Scenario: Sunday first is persisted

- **WHEN** the user selects "Sunday"
- **THEN** `firstday` is persisted as `su`

### Requirement: Cleantime unit order setting

The app SHALL offer "Cleantime sorting" (Cleantime sortering) with the options
"years - months - days" (`ymd`) and "days - months - years" (`dmy`). The default
is `ymd`. The value is persisted under `cleanTimeUnitSort`.

#### Scenario: Default unit order

- **WHEN** the Settings page opens with no stored value
- **THEN** "years - months - days" is selected

#### Scenario: Days first is persisted

- **WHEN** the user selects "days - months - years"
- **THEN** `cleanTimeUnitSort` is persisted as `dmy`

### Requirement: Default search radius setting

The app SHALL offer "Default search range" (Standard søgeradius) as a slider
from 5 km to 50 km in steps of 1 km, labelled "5 km" and "50 km" at its ends,
showing the current value as "Default search range = <n> km". The default is 15.
The value is persisted under `searchRange` when the user releases the slider.

#### Scenario: Default radius is 15 km

- **WHEN** the Settings page opens with no stored value
- **THEN** the slider is at 15 and the label reads "Default search range = 15 km"

#### Scenario: Radius is persisted on release

- **WHEN** the user drags the slider to 30 and releases it
- **THEN** `searchRange` is persisted as `30`

#### Scenario: Radius bounds

- **WHEN** the user drags the slider past either end
- **THEN** the value is clamped to 5 or 50

### Requirement: Selector dialogs

Each selector SHALL open a dialog listing its options with a "Cancel"
(Annuller) action that leaves the setting unchanged.

#### Scenario: Cancel keeps the value

- **WHEN** the user opens the language dialog and taps "Cancel"
- **THEN** the language is unchanged and nothing is persisted

### Requirement: Typed settings store

Settings SHALL be read through one typed `Settings` port with a sealed value per
setting; unknown or malformed stored values fall back to the default and are
overwritten with the default on the next write.

#### Scenario: Malformed stored value falls back

- **WHEN** `searchRange` is stored as `"abc"`
- **THEN** the radius reads as 15

## Intentional deltas from the legacy app

- The legacy Settings page fell back to `en` when `language` was unset, while app start-up wrote `da` on first launch. The default is `da` everywhere.
- The legacy `theme` key had a `selectTheme()` handler but no UI and no reader. It is dropped and not migrated.
- The legacy "Meetings nearby" page used its own fallback radius of 25 when `searchRange` was unset while Settings showed 15. There is one default: 15.
- Legacy persisted the radius on `ionBlur`; the rewrite persists on slider release, which is the same gesture without the focus quirk.
