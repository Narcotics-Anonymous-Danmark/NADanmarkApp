# Legacy Migration Specification

## Purpose

Users updating from the Ionic app must keep their settings, cleantime profiles
and listening positions. On first start the app imports the Ionic Storage
database once, translates each known key into the new typed settings, and never
touches it again.

> Source: App/src/app/app.module.ts (IonicStorageModule.forRoot()), App/config.xml (iOS scheme `ionic`, hostname `localhost`), App/src/app/providers/*.ts and App/src/app/media-player/resume-points.service.ts (key shapes) (legacy)

## Requirements

### Requirement: Legacy store location

The legacy store is the Ionic Storage (localForage) IndexedDB database named
`_ionicstorage` with the object store `_ionickv`, written by the WebView at the
origin `https://localhost` on Android and `ionic://localhost` on iOS. Values
are stored structured-cloned (strings, numbers, arrays, objects). The app SHALL
read it through a native plugin (`LegacyStore` port) that opens the WebView's
IndexedDB files for those origins read-only and returns all key/value pairs as
JSON.

#### Scenario: Android origin

- **WHEN** the plugin runs on Android
- **THEN** it reads the IndexedDB of origin `https://localhost`, database `_ionicstorage`, store `_ionickv`

#### Scenario: iOS origin

- **WHEN** the plugin runs on iOS
- **THEN** it reads the IndexedDB of origin `ionic://localhost`, database `_ionicstorage`, store `_ionickv`

### Requirement: Run once, before first render

The migration SHALL run at start-up before the first page is shown, only when
the marker setting `legacyMigration.completed` is absent. It sets the marker
(with the app version and a timestamp) when it finishes, whether or not any
legacy data was found. If the legacy store cannot be opened the marker is still
set and the app starts with defaults.

#### Scenario: Marker prevents a second run

- **WHEN** `legacyMigration.completed` is present
- **THEN** the legacy store is not opened

#### Scenario: No legacy database

- **WHEN** the plugin reports that no database exists
- **THEN** the marker is set and the app starts with default settings

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
| `meeting_formats_v1` | `{fetchedAt: ms, formats: [...]}` | `meetingFormatsCache` | copy when `formats` is a non-empty array; else drop |
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

### Requirement: Failure tolerance

A malformed value SHALL never abort the import: the key is skipped (default
applies) and the rest continues. A plugin failure (permission, corrupt
database, unsupported WebView data version) is logged and treated as "no legacy
data". The import SHALL complete within 2 s on a store of 100 keys; longer runs
are cut off and the marker is set with what was imported.

#### Scenario: One bad value does not block the rest

- **WHEN** `cleanDateProfiles` is the string `"oops"` and `language` is `"en"`
- **THEN** language is `en` and the profiles are the default

#### Scenario: Corrupt database

- **WHEN** the plugin throws while opening the database
- **THEN** the app starts with defaults and the marker is set

### Requirement: Idempotency and safety

The import SHALL never write to the legacy store. Running the translation twice
over the same input SHALL produce the same settings. Existing new-format values
(none expected on first run) are never overwritten by legacy values.

#### Scenario: Translation is a pure function

- **WHEN** the same legacy key/value map is translated twice
- **THEN** both results are equal

### Requirement: Observability

The import SHALL publish a `LegacyMigrationCompleted` domain event on the
`EventBus` with the counts of imported and skipped keys, and the Contact page
SHALL show "Imported settings from the previous version" under the version line
when the marker records at least one imported key.

#### Scenario: Event after import

- **WHEN** the import finishes with 6 imported and 1 skipped key
- **THEN** a `LegacyMigrationCompleted(imported: 6, skipped: 1)` event is published

## Intentional deltas from the legacy app

- `theme` is dropped (never read by the legacy app).
- `cleandate` changes from a zoned ISO timestamp to a calendar date.
- Resume-point indexes are rebuilt rather than trusted, so a stale legacy index cannot resurrect a cleared point.
- The Android origin is `https://localhost` because the legacy Android build used the default `https` scheme; an `ionic://` scheme at the top level would have broken the Cordova bridge and was never shipped.
