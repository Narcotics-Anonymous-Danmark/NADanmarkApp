# Design

## Context

Earlier slices provide:
- `LocalDate` with `plusDays`, `plusMonths` (day clamped to the month end),
  `plusYears`, `daysUntil`, `wholeMonthsUntil`, `wholeYearsUntil` and
  `compareTo`;
- `Clock.today()` and `Clock.now()`, with `TestTime` fakes;
- `KeyValueStorePort` with kernel codecs for structured values (e.g.
  `FormatsCacheCodec`);
- `SettingsPort`, which holds `cleanTimeUnitOrder` (`cleanTimeUnitSort`);
- `EventBus` with `LanguageChanged`;
- the legacy-store plugin, which already dumps every `_ionickv` key, including
  `cleanDateProfiles` and `activeProfile`;
- `LegacyMigration` with one import step for settings and one for the
  formats cache;
- `HomeBody(cards: ...)` and the `JftPreviewCard` pattern;
- a placeholder route body for `MenuDestination.cleantime`;
- `showNaOptionDialog`, `NaCard`, `NaIconButton`, golden and accessibility
  helpers;
- the legacy ARB keys for every cleantime text (`cleantime`, `datetime`,
  `entercleandate`, `cleantimein*`, `day(s)`, `month(s)`, `year(s)`,
  `birthday`, `*clean`, `or`, `newprofilenamehere`, `cancelbutton`,
  `addbutton`, `renameprofile`, `rename`, `areyousure`, `delete`, `cancel`,
  `ok`).

What is missing:
- Every cleantime type.
- Anything for local notifications.
- In the design system: a text field, a date picker, a confirm dialog and a
  carousel.
- The key tag images.
- `DateFormat`. Nothing formats month names yet.
- The DTO fields and the translator for the two legacy cleantime keys.

Constraints:
- Widgets layer only. `StatefulWidget` is allowed only in
  `na_design/lib/src/flutter_bridge/`. The dialogs, the picker and the
  carousel hold controllers, so they live there.
- Adapters may not import `na_l10n`. Notification texts are therefore
  rendered by the feature and handed to the port as values.
- `LayerRules`: `feature_cleantime` may not import `feature_settings`. It
  reads the unit order through `SettingsPort`, as slice 2 did for the radius.
- `zonedSchedule` rejects instants in the past, and iOS keeps at most 64
  pending local notifications.

See `proposal.md` for scope and the two spec deltas for behaviour.

## Goals / Non-Goals

**Goals:**
- All date logic is pure kernel code, verified against numbers computed by
  the legacy moment code. It is not checked against our own reading of
  moment.
- One use case owns "reschedule everything", so each trigger is a one-line
  call and every rule (past instants, sort, cap, ids, permission) is tested
  in one place.
- The page and Home are tested at the port boundary with
  `NotificationsMimic`. The adapter is tested against a mimic of the plugin's
  platform interface.

**Non-Goals:**
- A general notification framework. Slice 4's media controls use the media
  session, not this port.
- A device time-zone database. See D5.

## Decisions

### D1 Packages

- `na_kernel/lib/src/cleantime/`: domain types and arithmetic (D2), plus the
  codec and legacy translator in `lib/src/boundary/` (D3, D8).
- `na_ports`: `NotificationsPort` (D4), plus `Clock.instantOf` (D5).
- `adapter_notifications` (new): `LocalNotifications implements
  NotificationsPort`, and `notificationsOverrides({required
  FlutterLocalNotificationsPlatform platform})`.
- `feature_cleantime` (new):
  - `CleantimeProfilesStore`, `CleantimeController`, `AnniversarySchedule`;
  - `CleantimeBody`, `CleantimeHomeCards`;
  - the key tag assets.
- `na_design`: `showNaTextInputDialog`, `showNaConfirmDialog`,
  `showNaDatePicker`, `NaCarousel`, `NaIconButton.tone`, and
  `NaIcons.edit` / `NaIcons.trash` (D7).
- `feature_legacy_migration`: `_importCleantime` (D8).
- `app`:
  - route body and Home cards;
  - `notificationsOverrides` in `platformOverrides()`;
  - native configuration (D9).

### D2 Kernel cleantime types

```dart
extension type const ProfileName(String text) {}
extension type const ProfileIndex(int position) {}
extension type const YearCount(int value) {}
extension type const MonthCount(int value) {}
extension type const DayCount(int value) {}

final class CleantimeProfile { ProfileName name; LocalDate cleanDate; }

final class CleantimeProfiles {
  // invariant: entries non-empty, active in range
  List<CleantimeProfile> entries; ProfileIndex active;
  factory CleantimeProfiles.restore({entries, active, required CleantimeProfile fallback});
  CleantimeProfiles add / rename / changeDate / select / deleteActive({..., required CleantimeProfile fallback});
}

final class CleanTime {               // CleanTime.between({cleanDate, today})
  YearsMonthsDays yearsMonthsDays; MonthsDays monthsDays; DayCount days;
}

enum AnniversaryKind { oneDay, thirtyDays, sixtyDays, ninetyDays,
  sixMonths, nineMonths, oneYear, eighteenMonths, years }   // .asset: '1-day' ... 'x-years'

sealed class AnniversaryToday {}      // AnniversaryToday.of({cleanDate, today})
final class OnAnniversary extends AnniversaryToday { Anniversary anniversary; }
final class NoAnniversary extends AnniversaryToday {}

final class Anniversary { AnniversaryKind kind; AnniversaryAmount amount; }   // amount: Days | Months | Years
final class UpcomingAnniversary { Anniversary anniversary; LocalDate date; }
List<UpcomingAnniversary> upcomingAnniversaries({required LocalDate cleanDate, required LocalDate today});
```

- **Clean dates after today.** `CleanTime.between` uses `min(cleanDate,
  today)`, so a clean date after today reads 0. The upcoming list still
  works for such a date.
- **Month and year anniversaries.** They match on `cleanDate.plusMonths(n) ==
  today`, which is what moment's `diff(..., true) === n` means once clamping
  is accounted for.
- **No separate "1 year".** "1-year" is `oneYear` with `Years(1)`. The
  generic `years` kind starts at 2, which makes the legacy de-duplication
  step unnecessary.
- **Fixture table.** A one-off script, run outside the repo with the
  installed `../App/node_modules/moment`, runs the legacy `getCleanTimes`,
  `getCleanYearsMonthsDays`, `getCleanMonthsDays`, `cleanTimeTag` and
  `getNextAnniversaries` over a generated grid. The grid crosses each clean
  date with each "today":
  - clean dates: every day of 2019–2024, the month ends, and Feb 28 and
    Feb 29 of leap years;
  - "today": a dozen days, including leap days and the DST change dates.

  Its JSON output is committed as
  `na_testing/fixtures/cleantime/moment_cleantime.json`, next to the recorded
  BMLT fixtures, and `na_kernel/test/unit/cleantime_moment_test.dart` replays
  it through a test DTO. The script is described in the fixture's `source`
  field and is not committed as tooling.
- **Known difference from moment.** Moment 2.30's `monthDiff` reverses its
  arguments when the start day-of-month is smaller than the end day. This
  makes a month-end "today" one day after a clamped anniversary compare as
  exact. For example, clean date 2023-02-28 shows "1 year" on both
  2024-02-28 and 2024-02-29, while the breakdown on the 29th reads
  1 year, 0 months, 1 day. The rewrite tags only the real anniversary day,
  which agrees with the breakdown and the notification date. The fixture test
  allows exactly this class of mismatch and nothing else.
- **Alternative**: port moment's fractional `monthDiff`. Rejected because the
  fractions only feed `=== n` and `floor`, and both reduce to whole-month
  comparisons that `LocalDate` already has.

### D3 Profile storage

- Two keys:
  - `cleantimeProfiles`: `[{"name": "...", "cleanDate": "yyyy-MM-dd"}]`, through
    a `json_serializable` DTO;
  - `activeCleantimeProfile`: a decimal string.

  Both are kept in `SettingKeys`. They are not fields of `Settings`.
- **Codec.** `CleantimeProfilesCodec` decodes leniently: it drops entries with
  a blank name or an unparseable date, and turns a non-list into "no
  profiles". It encodes canonically. `LocalDate.parseIso` (new, strict
  `yyyy-MM-dd`, validated by round-trip) is shared with the legacy
  translator.
- **Store.** `CleantimeProfilesStore` (in the feature) reads and writes both
  keys through `KeyValueStorePort`:
  - `load()` returns `StoredProfiles` (sealed: `ProfilesFound`,
    `NoProfiles`);
  - `save()` writes the list first, then the index.
- **Why no port.** No platform API is involved. The store is a use case over
  `KeyValueStorePort`, like the formats cache.

### D4 NotificationsPort

```dart
abstract interface class NotificationsPort {
  Future<NotificationAccess> ensureAccess();               // Granted | Refused | Unsupported
  Future<Outcome<ScheduledCount, UnavailableFailure>> replaceAll({required NotificationChannelName channel, required List<PlannedNotification> notifications});
}
final class PlannedNotification { NotificationId id; Instant at; NotificationTitle title; NotificationBody body; }
```

- **`replaceAll` semantics.** It always cancels everything first. An empty
  list means "cancel only".
- **`ensureAccess`.** It asks the OS only when the state is not yet
  determined:
  - Android 13+ `POST_NOTIFICATIONS`, through
    `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission`;
  - iOS `requestPermissions(alert, badge, sound)`.
- **Adapter mapping.** `replaceAll` calls `cancelAll()`, then one
  `zonedSchedule` per entry with:
  - `TZDateTime.from(at.utc, tz.UTC)`;
  - `AndroidScheduleMode.inexactAllowWhileIdle`;
  - channel `cleanday`, with the name "Cleanday" passed in from the feature
    as `NotificationChannelName`;
  - the small icon `ic_notification`.

  A `PlatformException` maps to `NotificationFailure`.
- **Versions.** The adapter pins `flutter_local_notifications` 22.3.1,
  `flutter_local_notifications_platform_interface` 12.2.0 and `timezone`
  0.11.1. 22.3.2 was only nine days old at apply time, and 23.x is still a
  dev release that needs Flutter 3.44. The Android build adds
  `desugar_jdk_libs` 2.1.4.
- **Adapter shape.** `LocalNotifications` takes
  `FlutterLocalNotificationsPlatform.instance`. It switches on the
  registered Android or iOS implementation, initialises lazily and only
  once, and on Android asks for the permission at most once per run.
  Tests substitute subclasses of the plugin's own Android and iOS classes.
  Other platforms answer `unsupported` and schedule nothing.
- **Failures.** They are reported as the kernel's existing
  `UnavailableFailure`, because a new `Failure` subtype would break every
  exhaustive switch over `Failure`. The feature plans only instants at least
  one minute ahead, so the plugin's "date in the future" check (an `Error`,
  not an `Exception`) cannot fire.

### D5 Time zone

`Clock` gains `Instant instantOf({required LocalDate date, required
LocalTime time})`:
- `SystemClock` builds the device-local `DateTime(y, m, d, h, min).toUtc()`,
  which applies the device's DST rules for that future date;
- `FakeClock` uses `TestTime`'s fixed offset.

The port then works only with absolute instants, so the adapter needs only
`tz.UTC`. It needs neither `initializeTimeZones()` nor `flutter_timezone`.

**[Trade-off]** A notification keeps its instant if the user changes the
device time zone. It is corrected the next time Home opens, because the
schedule is rebuilt then.

### D6 Feature controllers

- **`CleantimeController`** (`Notifier<LoadResult<CleantimeView>>`):
  - `build` loads the store. On `NoProfiles` it creates the default,
    `ProfileName(l10n.cleantimeDefaultProfileName(1))`, and saves it.
  - It reads `SettingsPort` for the unit order and `Clock.today()` for the
    date.
  - Each edit applies the `CleantimeProfiles` operation, saves, rebuilds the
    view, and then calls `AnniversarySchedule.refresh()` without awaiting it.
  - `CleantimeView` holds the profiles, the `CleanTime`, the
    `AnniversaryToday` and the ordered groups. The widgets get typed values
    and pick ARB strings.
- **`AnniversarySchedule.refresh()`**:
  1. Load the profiles. `NoProfiles` means an empty plan.
  2. Compute `upcomingAnniversaries` for each profile, turn each into an
     instant with `instantOf(date, 10:00)`, and drop instants that are not
     after `Clock.now()`.
  3. Sort by instant, then by profile position, keep the first 64 and number
     them from 1.
  4. If the plan is not empty, `ensureAccess`. On `Refused` or `Unsupported`,
     schedule nothing.
  5. Call `replaceAll`.

  Texts come from `lookupAppLocalizations(language)` for the language in
  `SettingsPort`. Calls are serialised: a refresh that starts while one is
  running sets a "run again" flag, so the last state always wins. A failure
  is reported on the `EventBus` as `NotificationsFailed`, for logging only.
- **Triggers**:
  - `CleantimeHomeCards` and `CleantimeBody` watch
    `anniversaryRefreshOnShowProvider`, which calls `refresh()` once each
    time the page is built from the route;
  - `CleantimeController` calls it after each edit;
  - a keep-alive listener on `EventBus.on<LanguageChanged>()`
    (`anniversaryLanguageListenerProvider`) calls it. `AppStartup` in `app`
    reads it once, because `feature_shell` cannot import `feature_cleantime`.
- **`CleantimeHomeCards`** reads the store without creating a default, as
  the legacy Home did.

### D7 Design system

All in `flutter_bridge/` where state is needed:
- **`showNaTextInputDialog`**:
  - parameters: title, placeholder, initial text, cancel and confirm labels;
  - hosts an `EditableText`, autofocused, and the confirm button is disabled
    while the trimmed text is empty;
  - returns sealed `NaTextEntered(text)` or `NaTextCancelled`.
- **`showNaConfirmDialog`**: title, cancel and confirm labels. It returns
  `NaConfirmation.confirmed` or `NaConfirmation.declined`. The dialog buttons
  (`NaDialogTextButton`, which now takes `NaAvailability`) have no tone, so
  "Delete" is not drawn in red. The keys `na-dialog-cancel` and
  `na-dialog-confirm` are shared by every new dialog.
- **`showNaDatePicker`**:
  - three `ListWheelScrollView.useDelegate` wheels (day, month, year), from
    1950 to today;
  - month names are passed in by the caller as labels, so `na_design` stays
    free of `intl`. They come from `LocalDateFormat` in `na_l10n` (intl
    0.20.2), which also formats `dd MMM yyyy` and `dd. MMMM yyyy` and
    initialises intl's bundled locale data;
  - out-of-range items are dimmed; when scrolling ends past the maximum, the
    wheel animates back;
  - returns sealed `NaDatePicked(LocalDate)` or `NaDateCancelled`.
- **`NaCarousel`**: a `PageView` with a `PageController`, a fixed height of
  180, plus `NaPageDots`. The dots are hidden for a single page. A
  `NaBackdrop` makes the dots readable on Home's blue background. Each page
  has the semantics "Card n of m".
- **`NaIconButton`** gains `NaTone tone` (`neutral`, `success`, `primary`,
  `danger`). All existing call sites pass `neutral` explicitly.
- **Icons.** `NaIcons.edit` is `PhosphorIconsRegular.pencilSimple` and
  `NaIcons.trash` is `PhosphorIconsRegular.trash`.
- **Alternative**: a calendar-grid picker. Rejected because the legacy app
  used a wheel (ion-datetime). A wheel is also simpler to make accessible
  (each wheel is an adjustable semantics node).

### D8 Legacy migration

- **DTO.** `LegacyStoreDumpDto` gains `cleanDateProfiles` (lenient: a list
  of lenient `{name, cleandate}` maps, or anything else) and `activeProfile`
  (string or number).
- **Translator.** `LegacyCleantimeTranslator.translate({dump, required
  ProfileName Function(ProfileIndex) unnamed})` returns sealed
  `ImportCleantime(profiles)` or `SkipCleantime`, plus per-key import or skip
  for the counts.
- **Date rule.** The date is the leading `yyyy-MM-dd` of `cleandate`, which
  is exactly "the calendar date in its own offset", validated with
  `LocalDate.parseIso`.
- **Unnamed profiles.** `unnamed` is built by the feature from
  `lookupAppLocalizations` of the imported language.
- **Import step.** `LegacyMigration._importCleantime` writes through
  `CleantimeProfilesCodec`. Like the other steps, it never overwrites
  existing keys.
- **Existing tests.** Tests that assumed `cleanDateProfiles` was ignored are
  updated, because it now counts:
  - `legacy_settings_translation_test.dart:57`;
  - the "One bad value" unit and acceptance tests.

### D9 Native configuration

- **Android:**
  - `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`;
  - the plugin's `ScheduledNotificationReceiver` and
    `ScheduledNotificationBootReceiver`;
  - `isCoreLibraryDesugaringEnabled = true` with a pinned `desugar_jdk_libs`
    in `build.gradle.kts`;
  - `res/drawable/ic_notification.xml`, a white vector of the NA logo outline
    traced from `app/assets/branding/app_icon_foreground.png`.
- **iOS.** Set the `UNUserNotificationCenter` delegate in `AppDelegate.swift`,
  following the plugin's setup. It is built and checked on macOS, as an item
  added to slice 0's open task.

### D10 Assets

- Copy the 18 PNGs from `../App/src/assets/keytags/{da,en}/` to
  `feature_cleantime/assets/keytags/` (about 1.5 MB).
- Reference them through a `KeyTagImage` value built from
  `AnniversaryKind.asset` and `Language`, using `Image.asset(...,
  package: 'feature_cleantime')`. A unit test checks that every kind and
  language resolves to a bundled file. (`./bin/na gen assets` generates only
  launcher icons and splash screens.)

### D11 Localisation

New keys in both ARB files:

| Key | en | da |
|---|---|---|
| `cleantimeDefaultProfileName` | Profile {position} | Profil {position} |
| `cleantimeAddProfile` | Add profile | Tilføj profil |
| `cleantimeDeleteProfile` | Delete profile | Slet profil |
| `cleantimeKeyTag` | {anniversary} key tag | Nøglering for {anniversary} |
| `cleantimeHomeBreakdown` | {years}, {months}, {days} | {years}, {months}, {days} |
| `cleantimeCardPosition` | Card {n} of {m} | Kort {n} af {m} |
| `notificationCleandayTitle` | Cleanday - {name} | Mærkedag - {name} |
| `notificationCleandayBody` | Congratulations on {anniversary} | Tillykke med {anniversary} |
| `notificationChannelCleanday` | Cleanday | Mærkedag |

- Existing legacy keys are reused, and there is no ICU plural, matching the
  rest of the ARB.
- `docs/LEGACY_PARITY.md` cleantime rows are corrected to the keys actually
  used and to the new storage keys.

### D12 Tests

Kernel:
- the moment fixture table;
- value tests for `CleantimeProfiles` invariants;
- codec round trip and lenient decode;
- translator cases for every scenario of the migration delta.

Feature:
- controller tests with `TestTime`;
- `AnniversarySchedule` tests for past instants, sort, the cap, ids,
  refusal, failure and the "run again" flag.

Adapter:
- tests against `FlutterLocalNotificationsPlatform` mimics (Android and iOS
  subclasses), asserting the exact `zonedSchedule` arguments.

Acceptance:
- one test per scenario in both deltas, in `app/test_acceptance/cleantime/`
  and `legacy_migration/`, with `NotificationsMimic` bound by `TestContainer`.

Goldens and accessibility:
- each dialog, the picker, the carousel, every page state (with and without
  the Cleanday card, `ymd` and `dmy`) and the Home card.

Patrol:
- open Cleantime, add a profile, change the date, grant the notification
  permission with `$.native.grantPermissionWhenInUse()`, and expect the
  cards.

## Risks / Trade-offs

- **[Risk]** Our month arithmetic and moment's disagree on an edge case.
  → The D2 fixture table, computed with the legacy code itself, is the
  arbiter.
- **[Risk]** `flutter_local_notifications` needs Gradle desugaring and could
  clash with the AGP or Kotlin pins. → Pin it in a separate task that runs
  `./bin/na run android --emulator` before any feature code depends on it.
- **[Risk]** Android OEM battery savers delay inexact alarms. → A delay of
  minutes is acceptable for a 10:00 congratulation. Exact alarms are a
  documented non-goal.
- **[Risk]** Asking for the permission on Home's first open can surprise
  users. → It is asked only when a profile with an upcoming anniversary
  exists. That cannot happen before the user has opened the calculator or
  migrated profiles, and the legacy app did not ask at all.
- **[Trade-off]** The 64 cap drops far-future anniversaries for users with
  many profiles. They come back on a later reschedule as earlier ones pass.

## Migration Plan

The profiles migrate through the existing run-once legacy import (D8). They
live under new keys, so no existing new-format value can collide with them.
There is no rollback beyond the usual store rollback. Older Flutter builds
ignore the new keys.
