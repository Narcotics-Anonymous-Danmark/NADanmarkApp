# Spec Delta

## ADDED Requirements

### Requirement: Resume point import

The import SHALL read every legacy key that starts with `mediaResume.book.`
or `mediaResume.speak.`; the playlist id is the rest of the key (a book id or
a speak URL). A value counts when it is an object, or JSON text of an object,
whose `trackIndex` and `position` are numbers; `trackId` defaults to an empty
id, `duration` is kept only when it is a positive number, and `updatedAt` is
kept when it parses as ISO 8601, else the import time is used. Each kept
point is written under the same key, unless a point already exists there,
and `mediaResume.index.book` and `mediaResume.index.speak` are written with
exactly the kept points of their kind. The legacy index keys are never read.
Each kept point key counts as imported, each dropped point key as skipped;
the index keys are not counted.

#### Scenario: Resume points and index

- **WHEN** the store has `mediaResume.book.basic-text` = `{"trackId":"u4","trackIndex":4,"position":120,"duration":600,"updatedAt":"2026-05-01T10:00:00.000Z"}` and `mediaResume.speak.https://x.dk/a.mp3` = `{"trackId":"https://x.dk/a.mp3","trackIndex":0,"position":250,"updatedAt":"2026-05-02T10:00:00.000Z"}`
- **THEN** both points exist under the same keys
- **AND** `mediaResume.index.book` holds only `basic-text` and `mediaResume.index.speak` holds only the speak URL
- **AND** opening Basic Text shows "Continue listening" with chapter 5

#### Scenario: Stale legacy index is not trusted

- **WHEN** the store has `mediaResume.index.book` = `{"how-and-why": <point>}` but no `mediaResume.book.how-and-why`
- **THEN** no `how-and-why` point exists after the import

#### Scenario: Malformed points are skipped

- **WHEN** the store has `mediaResume.book.how-and-why` = `{"trackIndex":"two","position":5}` and `language = "en"`
- **THEN** no `how-and-why` point is imported, language is `en`
- **AND** the migration counts 1 imported and 1 skipped key
