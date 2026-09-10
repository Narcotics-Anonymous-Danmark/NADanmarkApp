# Readings Specification

## Purpose

Group readings ("Gruppeoplæsninger") shows the seven Danish readings used at
the start of NA meetings, one at a time, each on its traditional card colour.

> Source: App/src/app/pages/grc/grc.page.{ts,html} (legacy)

## Requirements

### Requirement: The seven readings

The app SHALL bundle these seven readings, in this order, with these background
colours and Danish titles:

| Id | Title (Danish) | Heading shown | Background |
|---|---|---|---|
| 0 | Hvem er en addict? | Hvem er en addict? | `#9AD9E8` |
| 1 | Hvad er NA's program? | Hvad er Narcotics Anonymous' program? | `#F8E937` |
| 2 | Hvorfor er vi her? | Hvorfor er vi her? | `#F0E4AF` |
| 3 | Sådan virker det | Sådan virker det | `#FFFFFF` |
| 4 | NA's Tolv Traditioner | Narcotics Anonymous' Tolv Traditioner | `#E0DAD8` |
| 5 | Vi kommer i bedring | Vi kommer i bedring | `#55CC80` |
| 6 | Bare for i dag | Bare for i dag | `#D7B7D6` |

The reading bodies are the Danish texts from the legacy template, kept as a
bundled asset. "Sådan virker det" contains the numbered Twelve Steps and "NA's
Tolv Traditioner" the numbered Twelve Traditions as ordered lists; "Bare for i
dag" has five hanging-indent "BARE FOR I DAG" paragraphs.

#### Scenario: Seven readings available

- **WHEN** the Readings page opens
- **THEN** the selector lists the seven titles in the order above

### Requirement: Selection

The page (title "Group readings" (Gruppeoplæsninger)) SHALL show a selector
(placeholder "Please select" (Vælg venligst)) that opens as a popover listing
the titles. The first reading is selected when the page opens. Selecting a
reading replaces the card content.

#### Scenario: First reading by default

- **WHEN** the page opens
- **THEN** "Hvem er en addict?" is shown

#### Scenario: Selecting another reading

- **WHEN** the user selects "Vi kommer i bedring"
- **THEN** its text is shown and the selector reads "Vi kommer i bedring"

### Requirement: Card appearance

The reading SHALL be shown in a square-cornered card with a 2 px black border,
inner margin 5 px, the reading's background colour, black text, a centred
24 px heading and 16 px body paragraphs with a 20 px first-line indent. The
page background behind the card follows the selected reading's id class so a
theme can tint it.

#### Scenario: Colour follows the reading

- **WHEN** "Sådan virker det" is selected
- **THEN** the card background is `#FFFFFF` with a 2 px black border

### Requirement: Text remains Danish

The reading texts SHALL be Danish regardless of the app language; only the page
title and placeholder follow the app language.

#### Scenario: English UI keeps Danish readings

- **WHEN** the app language is `en`
- **THEN** the title is "Group readings" and the readings are the Danish originals

## Intentional deltas from the legacy app

- Reading texts were inline HTML in the page template; they are a structured asset (heading, paragraphs, ordered lists) rendered by widgets, with no HTML.
- The placeholder "Vælg venligst" was hard-coded; it is localised.
