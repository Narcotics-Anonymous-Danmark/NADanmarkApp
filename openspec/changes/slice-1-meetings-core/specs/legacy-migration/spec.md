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
| `cleanDateProfiles` | `[{name: string, cleandate: ISO timestamp with offset}]` | `cleantimeProfiles` | keep entries with non-empty `name` and parseable `cleandate`; date = calendar date of the timestamp in its own offset |
| `activeProfile` | string index, e.g. `"1"` | `activeCleantimeProfile` | parse int; clamp to `[0, profiles.length - 1]`; 0 when unparseable |
| `meeting_formats_v1` | `{fetchedAt: ms, formats: [...]}` | `meetingFormatsCache` | copy when `fetchedAt` is a number and `formats` is a non-empty array; else drop |
| `mediaResume.book.<id>` | `{trackId, trackIndex, position, duration?, updatedAt}` | same key | copy when `trackIndex` and `position` are numbers |
| `mediaResume.speak.<url>` | same | same key | same rule |
| `mediaResume.index.book`, `mediaResume.index.speak` | `{<id>: point}` | same key | rebuilt from the imported points, not copied |

#### Scenario: Valid settings are copied

- **WHEN** the store has `language = "en"`, `firstday = "su"`, `searchRange = 30`, `cleanTimeUnitSort = "dmy"`
- **THEN** the new settings read `en`, `su`, 30 and `dmy`

#### Scenario: Cleantime profiles keep their calendar date

- **WHEN** `cleanDateProfiles` is `[{"name":"Anna","cleandate":"2020-05-03T00:00:00.000+02:00"}]`
- **THEN** one profile "Anna" with clean date 2020-05-03 is imported

#### Scenario: Active index is clamped

- **WHEN** two profiles are imported and `activeProfile` is `"5"`
- **THEN** the active index becomes 1

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
