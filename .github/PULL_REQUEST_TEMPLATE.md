<!--
Title: conventional commit, e.g. "feat(meetings): filter by weekday".
The type decides the release-notes section (feat → Nye funktioner, fix →
Fejlrettelser, scope l10n/i18n → Oversættelser, everything else → Vedligeholdelse).
-->

## What

<!-- One or two sentences. Link the issue if there is one. -->

## Spec

- [ ] Linked the OpenSpec change: `openspec/changes/<slug>/` (or "no spec change" and why)
- [ ] Every new `#### Scenario:` has an acceptance test with the scenario name as its description

## Tests

- [ ] Unit tests for new domain types and use cases
- [ ] Widget tests for new widgets
- [ ] Acceptance tests (`app/test_acceptance/`) for changed behaviour
- [ ] One Patrol E2E happy path (`app/integration_test/`) when a user-facing flow changed
- [ ] Coverage is not lower than on `main` (see the coverage comment on this PR)

## Translations

- [ ] Every new user-facing string is in both `app_da.arb` and `app_en.arb`
- [ ] No hard-coded Danish or English in widgets

## Checks

- [ ] `./bin/na check && ./bin/na test unit widget acceptance --coverage` passes locally
- [ ] No `flutter`, `dart`, `gradle` or `pod` called directly; everything through `./bin/na`
- [ ] Version numbers untouched (only `./bin/na release version` changes them)

## Screenshots

<!-- Before/after for visual changes, both platforms if the widget renders differently. -->
