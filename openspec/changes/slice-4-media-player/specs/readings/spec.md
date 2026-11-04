# Spec Delta

## MODIFIED Requirements

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
bundled JSON asset of blocks: paragraphs, numbered lists and hanging-indent
paragraphs, each a list of text spans that may be emphasised. "Sådan virker
det" contains the numbered Twelve Steps (step 3 ends with the emphasised "som
vi opfattede Ham") and "NA's Tolv Traditioner" the numbered Twelve Traditions;
"Bare for i dag" has five hanging-indent "BARE FOR I DAG" paragraphs.

#### Scenario: Seven readings available

- **WHEN** the Readings page opens and the selector is opened
- **THEN** it lists the seven titles in the order above

#### Scenario: Steps and traditions are numbered

- **WHEN** "Sådan virker det" and then "NA's Tolv Traditioner" are shown
- **THEN** each shows twelve numbered items, 1 to 12

### Requirement: Selection

The page (title "Group readings" (Gruppeoplæsninger)) SHALL show a selector
row at the top that shows only the selected title and a caret, with no label.
Tapping it opens the option sheet used by Settings, titled "Group readings",
listing the titles with the current one marked. The first reading
is selected when the page opens. Picking a reading replaces the card content;
cancelling keeps it.

#### Scenario: First reading by default

- **WHEN** the page opens
- **THEN** "Hvem er en addict?" is shown
- **AND** the selector shows "Hvem er en addict?" and no "Vælg venligst" label

#### Scenario: Selecting another reading

- **WHEN** the user selects "Vi kommer i bedring"
- **THEN** its text is shown and the selector reads "Vi kommer i bedring"

#### Scenario: Cancelling keeps the reading

- **WHEN** the user opens the selector on "Hvorfor er vi her?" and cancels
- **THEN** "Hvorfor er vi her?" is still shown

### Requirement: Card appearance

The reading SHALL be shown in a square-cornered card with a 2 px black border,
inner margin 5 px, the reading's background colour, black text, a centred
24 px heading and 16 px body paragraphs with a 20 px first-line indent.
Numbered items hang their number; the hanging-indent paragraphs are indented
20 px as a block. The page background behind the card is the reading's
colour.

#### Scenario: Colour follows the reading

- **WHEN** "Sådan virker det" is selected
- **THEN** the card background is `#FFFFFF` with a 2 px black border and the page background is `#FFFFFF`

### Requirement: Text remains Danish

The reading texts SHALL be Danish regardless of the app language; only the
page title and the sheet texts follow the app language.
When the asset cannot be read the page shows "The readings could not be
loaded." (Oplæsningerne kunne ikke indlæses.).

#### Scenario: English UI keeps Danish readings

- **WHEN** the app language is `en`
- **THEN** the title is "Group readings" and the readings are the Danish originals

#### Scenario: Readings that cannot be read

- **WHEN** the readings asset cannot be read
- **THEN** the page shows "The readings could not be loaded."
