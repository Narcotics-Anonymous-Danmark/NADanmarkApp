# Spec Delta

## MODIFIED Requirements

### Requirement: Keys and translation rules

The import SHALL translate these legacy keys; anything else in the store is
ignored:

| Legacy key | Legacy shape | New setting | Rule |
|---|---|---|---|
| `language` | `"da"` \| `"en"` | `language` | copy if valid, else default `da` |
| `firstday` | `"mo"` \| `"su"` | `firstDayOfWeek` | copy if valid, else `mo` |
| `searchRange` | number 5–50 | `searchRadiusKm` | copy if integer in range, else 15 |
| `cleanTimeUnitSort` | `"ymd"` \| `"dmy"` | `cleanTimeUnitOrder` | copy if valid, else `ymd` |
| `theme` | string | — | dropped |
| `cleanDateProfiles` | `[{name: string, cleandate: ISO timestamp}]` | `cleantimeProfiles` | keep entries whose `cleandate` starts with a valid `yyyy-MM-dd`; that date is the clean date (the calendar date of the timestamp in its own offset); a blank `name` becomes "Profile <position>" in the imported language |
| `activeProfile` | string index, e.g. `"1"`, or a number | `activeCleantimeProfile` | parse int; clamp to `[0, profiles.length - 1]`; 0 when unparseable; written only when profiles are imported |
| `meeting_formats_v1` | `{fetchedAt: ms, formats: [...]}` | `meetingFormatsCache` | copy when `fetchedAt` is a number and `formats` is a non-empty array; else drop |
| `mediaResume.book.<id>` | `{trackId, trackIndex, position, duration?, updatedAt}` | same key | copy when `trackIndex` and `position` are numbers |
| `mediaResume.speak.<url>` | same | same key | same rule |
| `mediaResume.index.book`, `mediaResume.index.speak` | `{<id>: point}` | same key | rebuilt from the imported points, not copied |

The legacy `cleandate` takes these forms, and all of them SHALL be accepted:
- `toISOString(true)` with the local offset, e.g.
  `2020-05-03T00:00:00.000+02:00`;
- whatever the legacy date picker wrote, an ISO string with any time and an
  offset or `Z`.

`cleanDateProfiles` counts as imported when at least one entry is kept, and
as skipped otherwise. An `activeProfile` that parses and sits next to
imported profiles counts as imported. Any other present `activeProfile`
counts as skipped.

#### Scenario: Valid settings are copied

- **WHEN** the store has `language = "en"`, `firstday = "su"`, `searchRange = 30`, `cleanTimeUnitSort = "dmy"`
- **THEN** the new settings read `en`, `su`, 30 and `dmy`

#### Scenario: Cleantime profiles keep their calendar date

- **WHEN** `cleanDateProfiles` is `[{"name":"Anna","cleandate":"2020-05-03T00:00:00.000+02:00"}]`
- **THEN** one profile "Anna" with clean date 2020-05-03 is imported

#### Scenario: Picker-written clean date

- **WHEN** `cleanDateProfiles` is `[{"name":"Bo","cleandate":"2019-11-30T23:30:00.000Z"}]`
- **THEN** one profile "Bo" with clean date 2019-11-30 is imported

#### Scenario: Unparseable entries are dropped

- **WHEN** `cleanDateProfiles` is `[{"name":"Anna","cleandate":"2020-05-03T00:00:00.000+02:00"},{"name":"X","cleandate":"soon"},{"name":"Y"}]`
- **THEN** only "Anna" is imported

#### Scenario: Unnamed profile keeps its date

- **WHEN** the language is `da` and `cleanDateProfiles` is `[{"name":"Anna","cleandate":"2020-05-03T00:00:00.000+02:00"},{"name":" ","cleandate":"2021-01-02T00:00:00.000+01:00"}]`
- **THEN** the profiles are "Anna" (2020-05-03) and "Profil 2" (2021-01-02)

#### Scenario: Active index is clamped

- **WHEN** two profiles are imported and `activeProfile` is `"5"`
- **THEN** the active index becomes 1

#### Scenario: Numeric active index

- **WHEN** two profiles are imported and `activeProfile` is the number `1`
- **THEN** the active index becomes 1

#### Scenario: Imported profiles appear in the calculator

- **WHEN** the legacy store holds profiles "Anna" and "Bo" with `activeProfile = "1"` and the app starts for the first time
- **THEN** the Cleantime page shows "Bo" selected with its legacy clean date
- **AND** Home shows a cleantime card for each profile

#### Scenario: Resume points and index

- **WHEN** the store has `mediaResume.book.basic-text` and `mediaResume.speak.<url>` points
- **THEN** both points exist under the same keys and both index entries are rebuilt from them

#### Scenario: Meeting formats cache is copied

- **WHEN** `meeting_formats_v1` is `{"fetchedAt": 1757500000000, "formats": [<one GetFormats row>]}`
- **THEN** `meetingFormatsCache` holds the same `fetchedAt` and row
- **AND** opening a meeting list within 7 days of `fetchedAt` makes no GetFormats request

#### Scenario: Empty meeting formats cache is dropped

- **WHEN** `meeting_formats_v1` is `{"fetchedAt": 1757500000000, "formats": []}`
- **THEN** nothing is written under `meetingFormatsCache` and the key counts as skipped

### Requirement: Failure tolerance

A malformed value SHALL never abort the import: the key is skipped (default
applies) and the rest continues. A plugin failure (permission, corrupt
database, unsupported WebView data version) is logged and treated as "no legacy
data". The import SHALL complete within 2 s on a store of 100 keys; longer runs
are cut off and the marker is set with what was imported.

#### Scenario: One bad value does not block the rest

- **WHEN** `cleanDateProfiles` is the string `"oops"` and `language` is `"en"`
- **THEN** language is `en` and the profiles are the default
- **AND** `cleanDateProfiles` counts as skipped

#### Scenario: Corrupt database

- **WHEN** the plugin throws while opening the database
- **THEN** the app starts with defaults and the marker is set
