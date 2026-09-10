# Just for Today Specification

## Purpose

"Just for Today" (Dagens tekst) shows the daily NA meditation for today's
calendar day from a bundled list of 366 entries. Home shows a truncated preview
card; the JFT page shows the full text.

> Source: App/src/app/pages/jft/jft.page.{ts,html}, App/src/app/providers/jft.service.ts, App/src/assets/data/jft.json, App/src/app/pages/home/home.page.html (legacy)

## Requirements

### Requirement: Bundled entries

The app SHALL bundle 366 JFT entries, one per calendar day including 29
February, each with the fields `day` (1–31 as text), `month` (Danish lowercase
month name: januar, februar, marts, april, maj, juni, juli, august, september,
oktober, november, december), `title`, `quote`, `source`, `text` and `jft`.

#### Scenario: Every day has an entry

- **WHEN** the entries are loaded
- **THEN** there are 366 entries and every (day, month) pair from 1 January to 31 December is present exactly once

### Requirement: Today's entry

The app SHALL pick the entry whose `day` equals today's day of month and whose
`month` equals the Danish name of today's month, using the device's local date
from the `Clock`.

#### Scenario: Entry for the current date

- **WHEN** today is 3 May
- **THEN** the entry with day `3` and month `maj` is selected

#### Scenario: Leap day

- **WHEN** today is 29 February
- **THEN** the entry with day `29` and month `februar` is selected

### Requirement: Full page layout

The JFT page (title "Just for today") SHALL show, in order: the date as
"<day>. <month>" right-aligned; the title centred bold; the quote centred
italic; the source right-aligned bold; the text; the `jft` paragraph with its
leading "Just for today:" (Bare for i dag:) in bold; and the footer "Copyright
(c) 2007-<current year>, NA World Services, Inc. All Rights Reserved" centred
small.

#### Scenario: Page fields in order

- **WHEN** the JFT page opens on 1 January 2026
- **THEN** it shows "1. januar", the title, quote, source, text, the jft paragraph with "Bare for i dag:" bold and "Copyright (c) 2007-2026, NA World Services, Inc. All Rights Reserved"

### Requirement: Home preview card

Home SHALL show a card titled "Just for today" containing the date, title,
quote, source and text in the same order as the page, clipped to 120 px height
with a fade to transparent over the lower half. Tapping the card opens `/jft`.
The card is absent while the entry is not yet loaded.

#### Scenario: Preview is clipped

- **WHEN** Home renders today's entry
- **THEN** the card content is at most 120 px tall and fades out at the bottom

#### Scenario: Preview opens the page

- **WHEN** the user taps the JFT card
- **THEN** the app navigates to `/jft`

### Requirement: Text remains Danish

The JFT texts SHALL be shown in Danish regardless of the app language; only the
page title, card title and copyright wording follow the app language.

#### Scenario: English UI keeps Danish text

- **WHEN** the app language is `en`
- **THEN** the page title is "Just for today" and the entry texts are the Danish originals

## Intentional deltas from the legacy app

- The legacy `jft` field was rewritten by string replacement into HTML (`<b>Bare for i dag:</b>`) and rendered with `innerHTML`; the rewrite renders the prefix bold with a rich text span, no HTML.
- Legacy loaded `assets/data/jft.json` over HTTP at runtime; the entries are a bundled asset loaded once through an adapter.
- The legacy month map keyed by two-digit month numbers is replaced by the same 12 Danish names as a typed enum.
