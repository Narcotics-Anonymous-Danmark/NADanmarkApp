# Localisation Specification

## Purpose

The app speaks Danish by default and English on request. Every user-facing
string lives in two ARB files kept in parity, and dates, numbers and collation
follow the chosen language.

> Source: App/src/assets/translations/{da,en}.json, App/src/app/app.component.ts, App/src/app/app.module.ts, App/src/app/pages/settings/settings.page.ts (legacy)

## Requirements

### Requirement: Supported languages and default

The app SHALL support exactly two languages, `da` and `en`. `da` is the default
when nothing is stored. The language is a setting, not the device locale.

#### Scenario: Device locale does not override the default

- **WHEN** the device locale is `en_US` and no language is stored
- **THEN** the app renders in Danish

### Requirement: ARB files and key parity

All strings SHALL live in `packages/core/na_l10n/lib/l10n/app_en.arb` and
`app_da.arb`. Both files SHALL have identical key sets; `./bin/na check arb`
fails otherwise. Keys are lowerCamelCase. Placeholders use ICU syntax; plurals
use ICU plural forms instead of separate singular/plural keys where the count
is a number.

#### Scenario: Missing key fails the check

- **WHEN** a key exists in `app_en.arb` but not in `app_da.arb`
- **THEN** `./bin/na check arb` exits non-zero naming the key

#### Scenario: Plural units

- **WHEN** a clean time of 1 day and of 2 days is rendered
- **THEN** the strings are "1 day" and "2 days" from one plural key

### Requirement: Legacy key mapping

Every legacy key used by a ported screen SHALL have one ARB key, documented in
`docs/LEGACY_PARITY.md`. Legacy keys that were unused, non-string
(`MONDAY_IS_FIRST_DAY_OF_WEEK`) or belonged to unported BMLT features are not
carried over. The nine Danish-only legacy keys get an English value where the
string is still used.

#### Scenario: Mapping table is complete

- **WHEN** an ARB key is added for a ported legacy string
- **THEN** `docs/LEGACY_PARITY.md` lists the legacy key next to it

### Requirement: Locale follows language

The `Locale` used for date formatting, number formatting and collation SHALL be
`da_DK` when the language is `da` and `en_GB` when it is `en`. Danish
collation is used for sorting Danish content (speak titles, format names)
regardless of UI language.

#### Scenario: Dates in English

- **WHEN** the language is `en`
- **THEN** an event on 2026-10-03 is shown as "03. Oct 2026"

#### Scenario: Dates in Danish

- **WHEN** the language is `da`
- **THEN** the same event is shown as "03. okt. 2026"

### Requirement: Immediate switch

Changing the language SHALL update every visible text without restarting the
app or leaving the current page.

#### Scenario: Live switch on Settings

- **WHEN** the user switches to English on the Settings page
- **THEN** the page title, labels and menu entries are English on the next frame

### Requirement: Content that stays Danish

JFT texts, group readings, audiobook chapter titles, speak data and meeting data
SHALL be shown as delivered, in Danish, in both UI languages. Meeting format
names follow the UI language through BMLT's `lang_enum` (`dk` for `da`, `en`
for `en`).

#### Scenario: Formats follow the UI language

- **WHEN** the language is `en`
- **THEN** meeting format chips show the English `name_string`

### Requirement: Notification and system texts

Local notification titles and bodies SHALL be produced from ARB strings in the
current language at scheduling time.

#### Scenario: Notifications rescheduled in the new language

- **WHEN** the user switches to English and opens Home
- **THEN** the rescheduled anniversary notifications have English text

## Intentional deltas from the legacy app

- Legacy pinned Angular `LOCALE_ID` to `da-DK` for all languages; dates and numbers now follow the language.
- Legacy da.json had 177 keys and en.json 168; the nine Danish-only keys (`COMING_SOON`, `COMING_SOON_BODY`, `LANGUAGE(S)`, `MONDAY_IS_FIRST_DAY_OF_WEEK`, `NA_HISTORY`, `SHOWOWNREGIONONTOPSETTING`, `STEPS`, `TRADITIONS`, `VIRTUAL_NA`) are dropped or given English parity as listed in `docs/LEGACY_PARITY.md`.
- Unused legacy BMLT keys (`DOIHAVETHEBMLT`, `IS_BMLT*`, `MAPRANGE`, `TIMEDISPLAY`, `24HR`, `12HR`, `MILES`, `KMS`, language names other than Danish/English, etc.) are not ported.
- Hard-coded Danish strings in templates (contact page, cleantime dialogs, GRC placeholder, notification texts) become ARB keys.
- Separate singular/plural keys (`DAY`/`DAYS`, `DAYCLEAN`/`DAYSCLEAN`, …) become ICU plurals.
