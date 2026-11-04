# Spec Delta

## MODIFIED Requirements

### Requirement: Typed settings store

Settings SHALL be read through one typed `Settings` port with a sealed value per
setting; unknown or malformed stored values fall back to the default and are
overwritten with the default on the next write. The settings are loaded at
start-up before the first page is shown; until then they are explicitly "not
loaded", and reading them in that state is an error, never a silent default.
When a write fails, the last settings that were read or saved stay in use and
the failure is kept with them.

#### Scenario: Malformed stored value falls back

- **WHEN** `searchRange` is stored as `"abc"`
- **THEN** the radius reads as 15

#### Scenario: A failed write keeps the settings in use

- **WHEN** the language is stored as `en` and writing to the store fails while the user picks Danish
- **THEN** the app stays in English and the settings are marked unsaved

#### Scenario: Settings are loaded before use

- **WHEN** the app starts
- **THEN** the settings are loaded before the first page is shown
