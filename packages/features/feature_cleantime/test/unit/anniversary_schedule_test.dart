@Tags(['unit'])
library;

import 'package:feature_cleantime/feature_cleantime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

Future<List<PlannedNotification>> refreshed(TestContainer harness) async {
  await harness.read(anniversaryScheduleProvider).refresh();
  return harness.notifications.scheduled;
}

Map<String, String> profilesCleanOn(List<LocalDate> dates) =>
    aStoredCleantimeProfiles(
      entries: List.unmodifiable(
        dates.indexed.map(
          (entry) => aCleantimeProfile(
            name: ProfileName('P${entry.$1}'),
            cleanDate: entry.$2,
          ),
        ),
      ),
    );

void main() {
  group('AnniversarySchedule', () {
    test('schedules every upcoming anniversary at 10:00 local', () async {
      final clean = september10.plusDays(days: -10);
      final harness = cleantimeHarness(storedValues: profilesCleanOn([clean]));
      final scheduled = await refreshed(harness);
      expect(
        scheduled.map((entry) => entry.at),
        UpcomingAnniversary.within(
          cleanDate: clean,
          today: september10,
        ).map((upcoming) => tenOClock(upcoming.date)),
      );
      expect(scheduled.map((entry) => entry.id), [
        for (var id = 1; id <= 8; id += 1) NotificationId(id),
      ]);
    });

    test('instants that have passed or are too close are skipped', () async {
      final harness = cleantimeHarness(
        utcHour: const HourOfDay(7),
        storedValues: profilesCleanOn([september10.plusDays(days: -30)]),
      );
      harness.time.advance(by: const Duration(minutes: 59, seconds: 30));
      final scheduled = await refreshed(harness);
      expect(scheduled.first.at, tenOClock(september10.plusDays(days: 30)));
    });

    test('an anniversary later today is still scheduled', () async {
      final harness = cleantimeHarness(
        utcHour: const HourOfDay(7),
        storedValues: profilesCleanOn([september10.plusDays(days: -30)]),
      );
      final scheduled = await refreshed(harness);
      expect(scheduled.first.at, tenOClock(september10));
      expect(
        scheduled.first.body,
        const NotificationBody('Tillykke med 30 dage'),
      );
    });

    test('sorts by instant then profile and keeps the first 64', () async {
      final harness = cleantimeHarness(
        storedValues: profilesCleanOn(List.filled(10, september10)),
      );
      final scheduled = await refreshed(harness);
      expect(scheduled, hasLength(64));
      expect(scheduled.first.title, const NotificationTitle('Mærkedag - P0'));
      expect(scheduled[9].title, const NotificationTitle('Mærkedag - P9'));
      expect(scheduled.last.id, const NotificationId(64));
      expect(
        scheduled.map((entry) => entry.at.utc),
        scheduled.map((entry) => entry.at.utc).toList()..sort(),
      );
    });

    test('texts follow the stored language', () async {
      final harness = cleantimeHarness(
        storedValues: {
          'language': 'en',
          ...profilesCleanOn([september10.plusDays(days: -80)]),
        },
      );
      final first = (await refreshed(harness)).first;
      expect(first.title, const NotificationTitle('Cleanday - P0'));
      expect(first.body, const NotificationBody('Congratulations on 90 days'));
      expect(
        harness.notifications.channels.last,
        const NotificationChannelName('Cleanday'),
      );
    });

    test('singular units in the body', () async {
      final harness = cleantimeHarness(
        storedValues: {
          'language': 'en',
          ...profilesCleanOn([september10]),
        },
      );
      expect(
        (await refreshed(harness)).first.body,
        const NotificationBody('Congratulations on 1 day'),
      );
    });

    test('an empty plan only cancels and never asks', () async {
      final harness = cleantimeHarness(
        permission: NotificationPermission.undetermined,
        storedValues: profilesCleanOn([
          const LocalDate(year: 2030, month: 1, day: 1),
        ]),
      );
      expect(await refreshed(harness), isEmpty);
      expect(harness.notifications.replaceCalls, const CallCount(1));
      expect(harness.notifications.promptCalls, const CallCount(0));
    });

    test('no stored profiles only cancels', () async {
      final harness = cleantimeHarness();
      expect(await refreshed(harness), isEmpty);
      expect(harness.notifications.replaceCalls, const CallCount(1));
    });

    test('a refused permission schedules nothing', () async {
      final harness = cleantimeHarness(
        permission: NotificationPermission.undetermined,
        prompt: NotificationPrompt.refuse,
        storedValues: profilesCleanOn([september10]),
      );
      expect(await refreshed(harness), isEmpty);
      expect(harness.notifications.promptCalls, const CallCount(1));
    });

    test('an unsupported platform schedules nothing', () async {
      final harness = cleantimeHarness(
        permission: NotificationPermission.unsupported,
        storedValues: profilesCleanOn([september10]),
      );
      expect(await refreshed(harness), isEmpty);
    });

    test('a failure is reported on the event bus', () async {
      final harness = cleantimeHarness(
        behaviour: ScheduleBehaviour.fail,
        storedValues: profilesCleanOn([september10]),
      );
      await refreshed(harness);
      expect(harness.events.recordedOf<NotificationsFailed>(), hasLength(1));
    });

    test('overlapping refreshes end with the latest state', () async {
      final harness = cleantimeHarness(
        storedValues: profilesCleanOn([september10.plusDays(days: -10)]),
      );
      final schedule = harness.read(anniversaryScheduleProvider);
      final first = schedule.refresh();
      await harness.storage.write(
        key: SettingKeys.language,
        value: 'en',
      );
      final second = schedule.refresh();
      final third = schedule.refresh();
      await Future.wait([first, second, third]);
      expect(harness.notifications.replaceCalls, const CallCount(2));
      expect(
        harness.notifications.scheduled.first.title,
        const NotificationTitle('Cleanday - P0'),
      );
      await schedule.refresh();
      expect(harness.notifications.replaceCalls, const CallCount(3));
    });
  });

  group('refresh triggers', () {
    test('showing a page refreshes once', () async {
      final harness = cleantimeHarness(
        storedValues: profilesCleanOn([september10]),
      );
      final subscription = harness.container.listen(
        anniversaryRefreshOnShowProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await flush();
      expect(harness.notifications.replaceCalls, const CallCount(1));
      expect(subscription.read(), ScheduleRefresh.requested);
    });

    test('a language change refreshes again', () async {
      final harness = cleantimeHarness(
        storedValues: profilesCleanOn([september10]),
      );
      expect(
        harness.read(anniversaryLanguageListenerProvider),
        ScheduleRefresh.listening,
      );
      harness.events.publish(
        event: const LanguageChanged(language: Language.english),
      );
      await flush();
      expect(harness.notifications.replaceCalls, const CallCount(1));
    });
  });
}
