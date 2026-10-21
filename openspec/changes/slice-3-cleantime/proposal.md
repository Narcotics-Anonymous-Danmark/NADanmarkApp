# Slice 3: cleantime and anniversary notifications

## Why

The Cleantime calculator is one of the most used parts of the app. Members
keep one or more clean dates, see their clean time and get a reminder on every
anniversary. It is mostly pure date logic, so it is the next safe slice after
the meeting pages. It also brings the first local notifications and the
`POST_NOTIFICATIONS` permission, and it finishes the legacy migration. Users
updating from the Ionic app must not lose their clean dates.

## What Changes

- **Cleantime domain** (`na_kernel`):
  - profiles that always hold at least one entry;
  - the three breakdowns (years / months / days, months / days, days);
  - anniversary detection and the upcoming anniversaries for the next two
    years.

  Month and year arithmetic follows moment's rules: the day of the month is
  clamped to the month's last day, and floors are taken. A fixture table
  computed with the legacy `moment` code checks this.
- **Profile storage** under `cleantimeProfiles` (JSON list of
  `{name, cleanDate: yyyy-MM-dd}`) and `activeCleantimeProfile`, through
  `KeyValueStorePort` and a kernel codec.
- **`/cleantime-counter` page** in a new `feature_cleantime` package:
  - profile selector, plus add / rename / delete buttons with their dialogs;
  - "First clean day" date picker with a maximum of today;
  - the "Cleanday" card with the key tag in the app language;
  - the three card groups, ordered by `cleanTimeUnitSort`.
- **Home cleantime cards**: a carousel with one card per profile, before the
  JFT card. Tapping a card opens the calculator.
- **Anniversary notifications**:
  - a new `NotificationsPort` and an `adapter_notifications` on
    `flutter_local_notifications`;
  - one notification at 10:00 local time per upcoming anniversary, at most
    64, rescheduled from scratch;
  - localised title and body;
  - permission requested the first time there is something to schedule.
- **Design system**: a text-input dialog, a confirm dialog, a wheel date
  picker, a carousel with page dots, toned icon buttons and the pencil and
  trash icons.
- **Legacy migration** of `cleanDateProfiles` and `activeProfile`:
  - accepts every `cleandate` form the legacy app wrote;
  - names unnamed profiles instead of dropping their dates;
  - counts both keys as imported or skipped.
- **Native configuration**:
  - Android: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, the plugin's
    receivers, core library desugaring and a monochrome notification icon;
  - iOS: the notification-center delegate. It is verified in slice 0's open
    macOS task.
- **Key tag images**: the 18 legacy PNGs (`da` and `en`), bundled in
  `feature_cleantime`.

Legacy behaviour not reproduced:
- Notification texts were hard-coded Danish with the typo "Tillyke". They are
  now localised and spelled correctly.
- The key tag always came from the `da` folder.
- The schedule was refreshed only when Home or the calculator was
  initialised. It now also refreshes after every profile change and after a
  language change.
- An anniversary dated today was scheduled again on every visit, even after
  10:00 had passed. Instants that have already passed are now skipped.
- Unit labels stayed singular after a value of 1 had been shown once.
- Adding a profile with an empty name was possible. "Create" and "Rename"
  are now disabled while the name is blank.
- The profile selector needed a separate "Select" button. A tap now picks
  the profile, as in the Settings dialogs.

## Non-goals

- Opening a specific page from a tapped notification. Tapping it opens the
  app as before.
- Refreshing the page at midnight while it stays open. Neither the legacy
  page nor Home did this.
- The JFT and events parts of Home (JFT exists, events are slice 6).
- Weekly clean time (`cleantimeinweeks` exists in the ARB but was never shown).
- Exact alarms. Inexact scheduling is enough for a 10:00 reminder and needs
  no `SCHEDULE_EXACT_ALARM`.
- Sharing a clean time or a key tag.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `cleantime`:
  - storage keys and blank-name rules;
  - tap-to-pick selector;
  - wheel picker behaviour and future dates;
  - month-end arithmetic and clean dates after today;
  - when notifications are rescheduled, past instants, the 64 cap and a
    refused permission;
  - Home with no profiles and the page dots.
- `legacy-migration`:
  - `cleandate` forms;
  - unnamed profiles;
  - a numeric `activeProfile`;
  - the import and skip counts for the two cleantime keys.

## Impact

- **New packages**:
  - `packages/features/feature_cleantime`
  - `packages/adapters/adapter_notifications`, on `flutter_local_notifications`
    with an exact pinned version and `timezone` (only `tz.UTC` is used)
- **Extended packages**:
  - `na_kernel`: cleantime types and arithmetic, profile codec, legacy
    cleantime translator, `Clock.instantOf`
  - `na_ports`: `NotificationsPort`
  - `na_design`: dialogs, date picker, carousel, icons, button tones
  - `na_l10n`: default profile name, notification texts, accessible labels
  - `na_testing`: `NotificationsMimic`, cleantime builders, legacy dump fields
  - `feature_legacy_migration`: the cleantime import step
  - `adapter_clock`: `instantOf`
  - `app`: route body, Home cards, overrides, acceptance tests, a Patrol test
- **Native**: `AndroidManifest.xml`, `app/android/app/build.gradle.kts`
  (desugaring), a notification drawable, and `AppDelegate.swift`.
- **Configuration**:
  - `coverage.yaml` floors for the two new packages;
  - `docs/LEGACY_PARITY.md` cleantime rows aligned with the ARB keys and the
    new storage keys.
