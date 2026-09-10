# Contact Specification

## Purpose

The About page ("Om denne app / Kontakt") tells users how to reach the meeting
list servant, links to NA websites and the source code, shows the build
information and carries the FIPT trademark notice.

> Source: App/src/app/pages/contact/contact.page.{ts,html}, App/src/environments/environment.ts (legacy)

## Requirements

### Requirement: Cards in order

The About page SHALL show these cards in this order:

1. Not-approved warning (only when the build is not NA approved, see below)
2. "Changes to the meeting list" (Ændringer til mødelisten) with the button "Write to the meeting list servant" (Skriv til mødelisteansvarlig)
3. "Narcotics Anonymous online" (Narcotics Anonymous på nettet) with the buttons "nadanmark.dk" and "na.org"
4. "About this app" (Om denne app) with the buttons "Source code" (Kildekode) and "Bug reports" (Fejlrapporter) followed by "Build type: <type>" and "Version: <x.y.z>"
5. "The fine print" (Det med småt) with the text "The NA logo is a registered trademark and used in accordance with the Fellowship Intellectual Property Trust (FIPT)."

#### Scenario: Cards are shown in order

- **WHEN** the About page opens in a production build
- **THEN** cards 2 to 5 are shown in that order and card 1 is absent

### Requirement: Links

The buttons SHALL open these targets in the system handler:

| Button | Target |
|---|---|
| Write to the meeting list servant | `mailto:modelisteansvarlig@nadanmark.dk` |
| nadanmark.dk | `https://nadanmark.dk/` |
| na.org | `https://na.org/` |
| Source code | `https://github.com/Narcotics-Anonymous-Danmark/App` |
| Bug reports | `mailto:app@nadanmark.dk` |

#### Scenario: Website opens externally

- **WHEN** the user taps "nadanmark.dk"
- **THEN** `https://nadanmark.dk/` is opened in the system browser

#### Scenario: Mail link opens the mail app

- **WHEN** the user taps "Bug reports"
- **THEN** `mailto:app@nadanmark.dk` is handed to the system

### Requirement: Build information

The page SHALL show "Build type: <APP_ENV>" and "Version: <x.y.z>" where
`APP_ENV` comes from the `--dart-define-from-file` environment (`dev`, `test`,
`release`) and the version from the build.

#### Scenario: Release build information

- **WHEN** the app is built with `env/release.json` and version 2.0.0
- **THEN** the card reads "Build type: release" and "Version: 2.0.0"

### Requirement: Not-approved warning

When the build is not NA approved the page SHALL show, as the first card, the
title "This app is not [yet] approved!" (Denne app er [endnu] ikke godkendt!)
and the text "This is a trial version. Until it has been approved by RSK, it
should not be used seriously." Approval is a build flag `NA_APPROVED`; release
builds set it to true.

#### Scenario: Warning hidden in approved builds

- **WHEN** `NA_APPROVED` is true
- **THEN** no warning card is shown

#### Scenario: Warning shown in trial builds

- **WHEN** `NA_APPROVED` is false
- **THEN** the warning card is the first card on the page

## Intentional deltas from the legacy app

- All card titles, button labels and the warning text were hard-coded Danish in the legacy template. They are localised (Danish and English).
- The legacy header was rendered inside the content scroll area; it is a normal fixed page header.
- The legacy commented-out "Known issues" card is not ported.
- The source-code link keeps pointing at the legacy repository until the rewrite is public; it is a config value, not a code constant.
