@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/cleantime.dart';
import '../support/pump_app.dart';

const LocalDate september10 = LocalDate(year: 2026, month: 9, day: 10);

void main() {
  group('Requirement: Profiles', () {
    testWidgets('First open creates the default profile', (tester) async {
      final app = await pumpCleantime(tester: tester);
      addTearDown(app.dispose);
      expect(selectedProfileName(tester), 'Profile 1');
      expect(savedProfiles(app), [
        aCleantimeProfile(
          name: const ProfileName('Profile 1'),
          cleanDate: september10,
        ),
      ]);
      expect(savedActive(app), '0');
    });

    testWidgets('Active profile is restored', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
          active: const ProfileIndex(1),
        ),
      );
      addTearDown(app.dispose);
      expect(selectedProfileName(tester), 'Bo');
    });

    testWidgets('Unreadable profiles fall back to the default', (
      tester,
    ) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: const {'cleantimeProfiles': '"oops"'},
      );
      addTearDown(app.dispose);
      expect(selectedProfileName(tester), 'Profile 1');
      expect(savedProfiles(app).single.cleanDate, september10);
    });

    testWidgets('Stored active index is clamped', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
          active: const ProfileIndex(7),
        ),
      );
      addTearDown(app.dispose);
      expect(selectedProfileName(tester), 'Bo');
    });
  });

  group('Requirement: Profile management', () {
    testWidgets('Add makes the new profile active', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [aCleantimeProfile(name: bo)],
        ),
      );
      addTearDown(app.dispose);
      await addNamedProfile(tester, anna);
      expect(selectedProfileName(tester), 'Anna');
      expect(
        savedProfiles(app).last,
        aCleantimeProfile(cleanDate: september10),
      );
      expect(savedActive(app), '1');
    });

    testWidgets('Rename keeps the date', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      await tapKey(tester, renameProfile);
      expect(find.text('Rename profile'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Anna',
      );
      await enterProfileName(tester, bo);
      await confirmDialog(tester);
      expect(selectedProfileName(tester), 'Bo');
      expect(savedProfiles(app), [aCleantimeProfile(name: bo)]);
    });

    testWidgets('Deleting the last profile recreates the default', (
      tester,
    ) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      await tapKey(tester, deleteProfile);
      expect(find.text('Are you sure?'), findsOneWidget);
      await confirmDialog(tester);
      expect(savedProfiles(app), [
        aCleantimeProfile(
          name: const ProfileName('Profile 1'),
          cleanDate: september10,
        ),
      ]);
    });

    testWidgets('Deleting selects the first profile', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
            aCleantimeProfile(name: carl),
          ],
          active: const ProfileIndex(2),
        ),
      );
      addTearDown(app.dispose);
      await tapKey(tester, deleteProfile);
      await confirmDialog(tester);
      expect(
        savedProfiles(app).map((profile) => profile.name),
        [anna, bo],
      );
      expect(selectedProfileName(tester), 'Anna');
    });

    testWidgets('Selecting a profile from the list', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
        ),
      );
      addTearDown(app.dispose);
      await tapKey(tester, profileSelector);
      await pickProfile(tester, bo);
      expect(selectedProfileName(tester), 'Bo');
      expect(savedActive(app), '1');
    });

    testWidgets('Blank names cannot be saved', (tester) async {
      final app = await pumpCleantime(tester: tester);
      addTearDown(app.dispose);
      await tapKey(tester, addProfile);
      await enterProfileName(tester, const ProfileName('   '));
      await confirmDialog(tester);
      expect(find.byType(NaTextInputSheet), findsOneWidget);
      expect(savedProfiles(app), hasLength(1));
    });

    testWidgets('Cancelling delete keeps the profile', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      await tapKey(tester, deleteProfile);
      await cancelDialog(tester);
      expect(savedProfiles(app), [aCleantimeProfile()]);
      expect(selectedProfileName(tester), 'Anna');
    });
  });

  group('Requirement: Clean date picker', () {
    testWidgets('Future dates are not selectable', (tester) async {
      final app = await pumpCleantime(tester: tester);
      addTearDown(app.dispose);
      await tapKey(tester, dateField);
      await turnWheel(
        tester: tester,
        wheel: DateWheel.day,
        steps: const WheelSteps(15),
      );
      await confirmDialog(tester);
      expect(savedProfiles(app).single.cleanDate, september10);
      expect(find.text('10 Sep 2026'), findsOneWidget);
    });

    testWidgets('Changing the date recalculates', (tester) async {
      final app = await pumpCleantime(tester: tester);
      addTearDown(app.dispose);
      await pickDate(
        tester: tester,
        from: september10,
        to: const LocalDate(year: 2020, month: 1, day: 15),
      );
      expect(
        savedProfiles(app).single.cleanDate,
        const LocalDate(year: 2020, month: 1, day: 15),
      );
      expect(groupValues(tester, const CardGroup(3)), ['2430 days']);
      expect(groupValues(tester, const CardGroup(1)), [
        '6 years',
        '7 months',
        '26 days',
      ]);
    });

    testWidgets('Cancelling the picker keeps the date', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      await tapKey(tester, dateField);
      await turnWheel(
        tester: tester,
        wheel: DateWheel.year,
        steps: const WheelSteps(-3),
      );
      await cancelDialog(tester);
      expect(savedProfiles(app), [aCleantimeProfile()]);
      expect(find.text('03 May 2020'), findsOneWidget);
    });

    testWidgets('Date is shown in the app language', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        language: inDanish,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      expect(find.text('03 maj 2020'), findsOneWidget);
    });
  });

  group('Requirement: Clean time breakdowns', () {
    testWidgets('Breakdown for a known date', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        today: const LocalDate(year: 2026, month: 3, day: 1),
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2023, month: 1, day: 31),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(groupValues(tester, const CardGroup(1)), [
        '3 years',
        '1 month',
        '1 day',
      ]);
      expect(groupValues(tester, const CardGroup(2)), ['37 months', '1 day']);
      expect(groupValues(tester, const CardGroup(3)), ['1125 days']);
      expect(find.text('- OR -'), findsNWidgets(2));
    });

    testWidgets('Singular units', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(1),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(groupValues(tester, const CardGroup(3)), ['1 day']);
    });

    testWidgets('Units return to plural', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(1),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      await pickDate(
        tester: tester,
        from: daysBefore(today: september10, days: const DayCount(1)),
        to: daysBefore(today: september10, days: const DayCount(2)),
      );
      expect(groupValues(tester, const CardGroup(3)), ['2 days']);
    });

    testWidgets('Month-end clean date', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        today: const LocalDate(year: 2024, month: 2, day: 29),
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2023, month: 8, day: 31),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(groupValues(tester, const CardGroup(1)), [
        '0 years',
        '6 months',
        '0 days',
      ]);
    });

    testWidgets('Clean date after today', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2026, month: 9, day: 12),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(groupValues(tester, const CardGroup(1)), [
        '0 years',
        '0 months',
        '0 days',
      ]);
      expect(groupValues(tester, const CardGroup(2)), ['0 months', '0 days']);
      expect(groupValues(tester, const CardGroup(3)), ['0 days']);
    });
  });

  group('Requirement: Anniversary detection and key tag', () {
    testWidgets('One year shows the year tag', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        language: inDanish,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2025, month: 9, day: 10),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(
        find.descendant(
          of: find.byKey(cleandayCard),
          matching: find.text('1 år'),
        ),
        findsOneWidget,
      );
      expect(
        keyTagAsset(tester),
        'packages/feature_cleantime/assets/keytags/da/1-year.png',
      );
    });

    testWidgets('Key tag follows the language', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(30),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(
        find.descendant(
          of: find.byKey(cleandayCard),
          matching: find.text('30 days'),
        ),
        findsOneWidget,
      );
      expect(
        keyTagAsset(tester),
        'packages/feature_cleantime/assets/keytags/en/30-days.png',
      );
    });

    testWidgets('Multi-year anniversary', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2021, month: 9, day: 10),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(
        find.descendant(
          of: find.byKey(cleandayCard),
          matching: find.text('5 years'),
        ),
        findsOneWidget,
      );
      expect(keyTagAsset(tester), endsWith('/en/x-years.png'));
    });

    testWidgets('Month end is not an anniversary a day late', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        today: const LocalDate(year: 2024, month: 2, day: 29),
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2023, month: 2, day: 28),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(find.byKey(cleandayCard), findsNothing);
    });

    testWidgets('No anniversary', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(45),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(find.byKey(cleandayCard), findsNothing);
    });
  });

  group('Requirement: Unit order setting', () {
    testWidgets('Days first', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: {
          'cleanTimeUnitSort': 'dmy',
          ...storedProfiles(entries: [aCleantimeProfile()]),
        },
      );
      addTearDown(app.dispose);
      expect(groupTitles(tester, const CardGroup(1)), [
        'Clean days',
        'Clean months',
        'Clean years',
      ]);
      expect(groupTitles(tester, const CardGroup(2)), [
        'Clean days',
        'Clean months',
      ]);
    });
  });

  group('Requirement: Anniversary notifications', () {
    testWidgets('Notifications are rescheduled from scratch', (tester) async {
      final recent = daysBefore(today: september10, days: const DayCount(10));
      final old = september10.plusYears(years: -4).plusDays(days: -200);
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(cleanDate: recent),
            aCleantimeProfile(name: bo, cleanDate: old),
          ],
        ),
      );
      addTearDown(app.dispose);
      final scheduled = app.notifications.scheduled;
      expect(
        scheduled.map((entry) => entry.id.value),
        List.generate(10, (index) => index + 1),
      );
      expect(
        scheduled.map((entry) => entry.at).toSet(),
        {
          ...UpcomingAnniversary.within(cleanDate: recent, today: september10),
          ...UpcomingAnniversary.within(cleanDate: old, today: september10),
        }.map((upcoming) => tenOClock(upcoming.date)).toSet(),
      );
      expect(
        scheduled.map((entry) => entry.at.utc),
        scheduled.map((entry) => entry.at.utc).toList()..sort(),
      );
    });

    testWidgets('Notification text is localised', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(80),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      final ninety = app.notifications.scheduled.first;
      expect(ninety.title, const NotificationTitle('Cleanday - Anna'));
      expect(ninety.body, const NotificationBody('Congratulations on 90 days'));
    });

    testWidgets('Danish notification text', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        language: inDanish,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2025, month: 10, day: 1),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      final oneYear = app.notifications.scheduled.firstWhere(
        (entry) =>
            entry.at ==
            tenOClock(const LocalDate(year: 2026, month: 10, day: 1)),
      );
      expect(oneYear.title, const NotificationTitle('Mærkedag - Anna'));
      expect(oneYear.body, const NotificationBody('Tillykke med 1 år'));
    });

    testWidgets('Nothing to schedule', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        permission: NotificationPermission.undetermined,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2030, month: 1, day: 1),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(
        app.notifications.replaceCalls,
        isNot(const CallCount(0)),
      );
      expect(app.notifications.scheduled, isEmpty);
      expect(app.notifications.promptCalls, const CallCount(0));
    });

    testWidgets('Passed time today is skipped', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: const LocalDate(year: 2026, month: 8, day: 11),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      final first = app.notifications.scheduled.first;
      expect(
        first.at,
        tenOClock(const LocalDate(year: 2026, month: 10, day: 10)),
      );
      expect(first.body, const NotificationBody('Congratulations on 60 days'));
      expect(
        app.notifications.scheduled.map((entry) => entry.at),
        isNot(contains(tenOClock(september10))),
      );
    });

    testWidgets('Editing a date reschedules', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(2),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      final before = app.notifications.replaceCalls;
      await pickDate(
        tester: tester,
        from: daysBefore(today: september10, days: const DayCount(2)),
        to: daysBefore(today: september10, days: const DayCount(5)),
      );
      expect(app.notifications.replaceCalls, isNot(before));
      expect(
        app.notifications.scheduled.first.at,
        tenOClock(
          daysBefore(
            today: september10,
            days: const DayCount(5),
          ).plusDays(days: 30),
        ),
      );
    });

    testWidgets('Language change reschedules', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: settingsPath,
        language: inDanish,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(80),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      await chooseOption(
        tester: tester,
        row: const Key('settings-language'),
        option: 'Engelsk',
      );
      expect(
        app.notifications.scheduled.first.body,
        const NotificationBody('Congratulations on 90 days'),
      );
    });

    testWidgets('At most 64 notifications', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(
          entries: List.generate(
            10,
            (index) => aCleantimeProfile(
              name: ProfileName('P$index'),
              cleanDate: september10,
            ),
          ),
        ),
      );
      addTearDown(app.dispose);
      final scheduled = app.notifications.scheduled;
      expect(scheduled, hasLength(64));
      expect(scheduled.last.id, const NotificationId(64));
      expect(
        scheduled.map((entry) => entry.at).toSet(),
        hasLength(7),
      );
    });

    testWidgets('Permission refused', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        permission: NotificationPermission.undetermined,
        prompt: NotificationPrompt.refuse,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(
              cleanDate: daysBefore(
                today: september10,
                days: const DayCount(10),
              ),
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(app.notifications.scheduled, isEmpty);
      expect(app.notifications.promptCalls, const CallCount(1));
      expect(groupValues(tester, const CardGroup(3)), ['10 days']);
    });
  });

  group('Requirement: Home cleantime cards', () {
    testWidgets('Home card content', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        language: inDanish,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('6 år, 4 måneder, 7 dage'), findsOneWidget);
      expect(find.text('03. maj 2020'), findsOneWidget);
    });

    testWidgets('Card opens the calculator', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(entries: [aCleantimeProfile()]),
      );
      addTearDown(app.dispose);
      await tapKey(tester, const Key('home-cleantime-card-0'));
      expect(find.byKey(profileSelector), findsOneWidget);
      expect(selectedProfileName(tester), 'Anna');
    });

    testWidgets('One card per profile', (tester) async {
      final app = await pumpCleantime(
        tester: tester,
        location: homePath,
        storedValues: storedProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
        ),
      );
      addTearDown(app.dispose);
      await tester.fling(find.byKey(homeCarousel), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Bo'), findsOneWidget);
    });

    testWidgets('No profiles, no carousel', (tester) async {
      final app = await pumpCleantime(tester: tester, location: homePath);
      addTearDown(app.dispose);
      expect(find.byKey(homeCarousel), findsNothing);
      expect(find.text('Just for today'), findsWidgets);
      expect(app.storage.snapshot.containsKey('cleantimeProfiles'), isFalse);
    });
  });
}
