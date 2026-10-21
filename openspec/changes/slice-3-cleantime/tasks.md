# Tasks

## 1. Kernel (D2, D3, D5)

- [x] 1.1 Generate the moment fixture table: a throwaway script in the session scratchpad requires `../App/node_modules/moment(-timezone)` and replays the legacy `getCleanTimes`, `getCleanYearsMonthsDays`, `getCleanMonthsDays`, `cleanTimeTag` and `getNextAnniversaries` over the D2 grid, writing `packages/core/na_kernel/test/fixtures/cleantime_moment.json` (fixture header records how it was produced); verify the file covers month ends, Feb 28/29 and the DST dates
- [x] 1.2 Add `LocalDate.parseIso` (strict `yyyy-MM-dd`, round-trip validated) and `Clock.instantOf({date, time})` with `SystemClock` and `FakeClock` implementations; verify with unit tests (invalid months/days, leap day, `TestTime` offset, a DST date on the system clock)
- [x] 1.3 Add `na_kernel/lib/src/cleantime/`: `ProfileName`, `ProfileIndex`, counts, `CleantimeProfile`, `CleantimeProfiles` (invariant-preserving add / rename / changeDate / select / deleteActive / restore with clamping), `CleanTime.between`, `AnniversaryKind`, `Anniversary`, `AnniversaryToday`, `upcomingAnniversaries`; verify with the fixture table test, invariant tests and the spec examples (2023-01-31 → 2026-03-01, 2023-08-31 → 2024-02-29, clean date after today, both upcoming-window scenarios)
- [x] 1.4 Add `SettingKeys.cleantimeProfiles` / `activeCleantimeProfile` and `CleantimeProfilesCodec` with its `json_serializable` DTO (`./bin/na gen json`); verify round trip, lenient decode of `"oops"`, blank names and bad dates, and the active index codec
- [x] 1.5 Add `LegacyStoreDumpDto.cleanDateProfiles` / `activeProfile` and `LegacyCleantimeTranslator`; verify one unit test per scenario of the legacy-migration delta (both `cleandate` forms, dropped entries, unnamed profile naming, clamped and numeric index, `"oops"` skipped) and update `legacy_settings_translation_test.dart` for the new counting

## 2. Ports, builders and mimics (D4, D12)

- [x] 2.1 Add `NotificationsPort`, `PlannedNotification`, `NotificationId`, `NotificationTitle`, `NotificationBody`, `NotificationChannelName`, `NotificationAccess` (`Granted`, `Refused`, `Unsupported`), `ScheduledCount`, `NotificationFailure`, `NotificationsFailed` event, and the unbound `notificationsProvider`; verify that the unbound-port unit test lists the new port
- [x] 2.2 Add `NotificationsMimic` (scripted access answer, failure injection, `scheduled` snapshot, access-request and cancel counts) bound by default in `TestContainer`; add builders `aCleantimeProfile`, `aCleantimeProfiles`, `aStoredCleantimeProfiles`, and `cleanDateProfiles` / `activeProfile` on `aLegacyStoreDump`; verify with mimic unit tests

## 3. Acceptance tests first (red)

- [x] 3.1 Extend `pumpApp` / `AppHarness` with `notifications` and helpers in `app/test_acceptance/support/cleantime.dart` (open page, profile header actions, pick date through the wheels, read cards); verify the existing acceptance suite still passes
- [x] 3.2 Write one `testWidgets` per scenario of the cleantime delta in `app/test_acceptance/cleantime/` and the new or changed legacy-migration scenarios in `app/test_acceptance/legacy_migration/`; verify they fail because the feature is missing, not because of harness errors

## 4. Adapter (D4, D9)

- [x] 4.1 Create `packages/adapters/adapter_notifications` (`version: 0.0.0`, workspace, `coverage.yaml` adapter default) pinning the newest `flutter_local_notifications` and matching `timezone` that resolve with the workspace; add core library desugaring to `app/android/app/build.gradle.kts`; record exact versions in design D4; verify with `./bin/na check deps` and `./bin/na run android --emulator` booting unchanged
- [x] 4.2 Implement `LocalNotifications` and `notificationsOverrides`: access mapping per platform, `cancelAll` + `zonedSchedule` with `tz.UTC`, `inexactAllowWhileIdle`, channel `cleanday`, icon `ic_notification`, `PlatformException` → `NotificationFailure`; verify with adapter tests against Android and iOS `FlutterLocalNotificationsPlatform` mimics asserting exact arguments, an empty list (cancel only), and the failure mapping

## 5. Feature use cases (D3, D6)

- [x] 5.1 Create `packages/features/feature_cleantime` with `CleantimeProfilesStore`; verify load/save over `KeyValueStoreMimic`, `NoProfiles` for missing or unreadable values, and index clamping
- [x] 5.2 Implement `AnniversarySchedule.refresh()`; verify with `TestTime` unit tests for 10:00 instants, past instants skipped, sort and 64 cap, ids from 1, `en`/`da` texts, empty plan (cancel only, no access request), refusal, failure → `NotificationsFailed`, and two overlapping refreshes ending with the latest state
- [x] 5.3 Implement `CleantimeController` and `CleantimeView` (default profile, unit order from `SettingsPort`, every edit saving and refreshing); verify with unit tests for each profile-management scenario and that the default name follows the language
- [x] 5.4 Add `anniversaryRefreshOnShowProvider` and `anniversaryLanguageListenerProvider`; verify that showing triggers one refresh and a `LanguageChanged` event triggers another

## 6. Design system (D7)

- [x] 6.1 Add `NaTone` to `NaIconButton` (update every call site), `NaIcons.edit` and `NaIcons.trash`; verify widget tests and that existing goldens are unchanged
- [x] 6.2 Add `showNaTextInputDialog` and `showNaConfirmDialog` in `flutter_bridge/`; verify widget tests for confirm, cancel, the barrier, trimmed-blank disabling and initial text
- [x] 6.3 Add `showNaDatePicker` (three wheels, locale month names, maximum date snapping, dimmed future items, `initializeDateFormatting` in `NaApp`); verify widget tests for pick, cancel, snapping back from a future day and month, Feb 29 handling, and semantics of each wheel
- [x] 6.4 Add `NaCarousel` with `NaPageDots`; verify swipe, hidden dots for one page and the "Card n of m" semantics

## 7. Pages and wiring (D6, D10, D11)

- [x] 7.1 Add the D11 keys to both ARB files, regenerate with `./bin/na gen l10n`, and correct the cleantime rows of `docs/LEGACY_PARITY.md`; verify with `./bin/na check arb`
- [x] 7.2 Copy the 18 key tag PNGs into `feature_cleantime/assets/keytags/{da,en}/` and add `KeyTagImage`; verify the asset-resolution unit test for every kind × language
- [x] 7.3 Build `CleantimeBody` (profile header, date field, Cleanday card, three groups with "- OR -" rows, loading and failure states); verify widget tests per state and per header action
- [x] 7.4 Build `CleantimeHomeCards` (carousel of profile cards, none without profiles); verify widget tests for one, two and zero profiles and the tap callback
- [x] 7.5 Wire `MenuDestination.cleantime` to `CleantimeBody`, put `CleantimeHomeCards` before `JftPreviewCard` in Home, add `notificationsOverrides(plugin: FlutterLocalNotificationsPlugin())` (initialised with the Android icon and iOS no-prompt settings) to `platformOverrides()`, and read the language listener in `AppStartup`; verify that the acceptance tests from 3.2 pass with `./bin/na test acceptance`
- [x] 7.6 Add `_importCleantime` to `LegacyMigration` (unnamed namer from `lookupAppLocalizations`, never overwriting, counts); verify feature unit tests and update the "One bad value" unit and acceptance tests

## 8. Native configuration (D9)

- [x] 8.1 Add `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, the plugin receivers and `res/drawable/ic_notification.xml` to Android; verify on the emulator: set a clean date so an anniversary falls tomorrow, grant the permission, move the emulator clock past 10:00 the next day with `adb shell` and see the notification with the monochrome icon (also after a reboot)
- [x] 8.2 Add the `UNUserNotificationCenter` delegate to `AppDelegate.swift`; add "build iOS, check the notification permission prompt and a delivered notification" to slice 0's open macOS task

## 9. Goldens and accessibility (D12)

- [x] 9.1 Add goldens and `expectAccessible` for both dialogs, the date picker, the carousel, the Home card, and `CleantimeBody` with and without the Cleanday card in `ymd` and `dmy`; verify with `./bin/na test widget`

## 10. End to end and definition of done

- [x] 10.1 Add the Patrol test `app/integration_test/cleantime_test.dart` (open Cleantime, add a profile, pick a date, grant the notification permission, expect the cards); verify with `./bin/na test e2e --device <android emulator>`
- [x] 10.2 Capture da/en Android screenshots (calculator with and without Cleanday card, add dialog, date picker, Home carousel) into `docs/screenshots/cleantime/`; add iOS screenshots to slice 0's open macOS task
- [x] 10.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check` and confirm every floor is met, including `feature_cleantime` and `adapter_notifications`

## Workflow follow-up

- On archive, add to "Intentional deltas from the legacy app" in `openspec/specs/cleantime/spec.md`:
  - profiles move to `cleantimeProfiles` / `activeCleantimeProfile` with calendar dates
  - notifications are also rescheduled after profile edits and language changes
  - past instants are skipped instead of firing on every visit; at most 64 are scheduled, earliest first
  - blank profile names cannot be saved; the selector picks on tap without a "Select" button
  - the date picker uses the locale's month names and disables future dates
  - unit labels return to plural; a clean date after today reads 0
  - a month-end day right after a clamped anniversary is no longer tagged as a second Cleanday (moment's reversed month-end diff)
  - Home hides the carousel without profiles and the dots with one profile
- On archive, add to `openspec/specs/legacy-migration/spec.md` deltas: unnamed legacy profiles are kept with a generated name instead of being dropped
- Archive with `/opsx:archive slice-3-cleantime` after the PR is merged.
