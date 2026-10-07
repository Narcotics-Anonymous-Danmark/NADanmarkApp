# Spec Delta

## MODIFIED Requirements

### Requirement: Content that stays Danish

JFT texts, group readings, audiobook chapter titles, speak data and meeting data
SHALL be shown as delivered, in Danish, in both UI languages. Meeting format
names follow the UI language through BMLT's `lang_enum` (`da` for `da`, `en`
for `en`); a format with no row in the UI language shows its `en` row, then its
first row.

#### Scenario: Formats follow the UI language

- **WHEN** the language is `en`
- **THEN** meeting format chips show the English `name_string`

#### Scenario: Danish-only format in English

- **WHEN** the language is `en` and a format has only a `da` row
- **THEN** its chip shows the Danish `name_string`
