@Tags(['unit'])
library;

import 'package:feature_cleantime/feature_cleantime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

Future<CleantimeController> open(TestContainer harness) async {
  final subscription = harness.container.listen(
    cleantimeControllerProvider,
    (previous, next) {},
  );
  addTearDown(subscription.close);
  await flush();
  return harness.read(cleantimeControllerProvider.notifier);
}

CleantimeView viewOf(TestContainer harness) =>
    switch (harness.read(cleantimeControllerProvider)) {
      Loaded(:final value) => value,
      Loading() || Failed() => throw StateError('not loaded'),
    };

List<CleantimeProfile> saved(TestContainer harness) =>
    switch (const CleantimeProfilesCodec().decodeProfiles(
      text: harness.storage.snapshot['cleantimeProfiles'] ?? '',
    )) {
      Ok(:final value) => value,
      Err() => const [],
    };

final CleantimeProfile carl = aCleantimeProfile(
  name: const ProfileName('Carl'),
);

void main() {
  group('CleantimeController', () {
    test('starts loading', () {
      final harness = cleantimeHarness();
      expect(
        harness.read(cleantimeControllerProvider),
        isA<Loading<CleantimeView>>(),
      );
    });

    test('first open creates and saves the default profile', () async {
      final harness = cleantimeHarness();
      await open(harness);
      final expected = aCleantimeProfile(
        name: const ProfileName('Profil 1'),
        cleanDate: september10,
      );
      expect(viewOf(harness).profiles.entries, [expected]);
      expect(saved(harness), [expected]);
      expect(harness.notifications.replaceCalls, const CallCount(1));
    });

    test('the default name follows the language', () async {
      final harness = cleantimeHarness(storedValues: const {'language': 'en'});
      await open(harness);
      expect(viewOf(harness).active.name, const ProfileName('Profile 1'));
    });

    test('stored profiles are restored without saving', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
          active: const ProfileIndex(1),
        ),
      );
      await open(harness);
      expect(viewOf(harness).active.name, bo);
      expect(harness.notifications.replaceCalls, const CallCount(0));
    });

    test('add, rename, select, change date and delete persist', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
      );
      final controller = await open(harness);
      await controller.add(name: const ProfileName('  Bo '));
      expect(
        viewOf(harness).active,
        aCleantimeProfile(name: bo, cleanDate: september10),
      );
      await controller.rename(name: const ProfileName('Carl'));
      await controller.changeDate(
        cleanDate: const LocalDate(year: 2020, month: 5, day: 3),
      );
      expect(saved(harness), [aCleantimeProfile(), carl]);
      await controller.select(index: const ProfileIndex(0));
      expect(harness.storage.snapshot['activeCleantimeProfile'], '0');
      await controller.deleteActive();
      expect(saved(harness), [carl]);
      await controller.deleteActive();
      expect(saved(harness).single.name, const ProfileName('Profil 1'));
      await flush();
      expect(harness.notifications.replaceCalls, isNot(const CallCount(0)));
    });

    test('groups follow the unit order', () async {
      final harness = cleantimeHarness(
        storedValues: {
          'cleanTimeUnitSort': 'dmy',
          ...aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
        },
      );
      await open(harness);
      expect(viewOf(harness).groups.first, const [
        DaysAmount(days: DayCount(7)),
        MonthsAmount(months: MonthCount(4)),
        YearsAmount(years: YearCount(6)),
      ]);
      expect(viewOf(harness).groups.last, const [
        DaysAmount(days: DayCount(2321)),
      ]);
    });

    test('the anniversary of today is known', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(
          entries: [
            aCleantimeProfile(cleanDate: september10.plusYears(years: -1)),
          ],
        ),
      );
      await open(harness);
      expect(viewOf(harness).anniversaryToday, isA<OnAnniversary>());
    });

    test('edits before loading are ignored', () async {
      final harness = cleantimeHarness();
      await harness.read(cleantimeControllerProvider.notifier).rename(name: bo);
      expect(
        harness.storage.snapshot.containsKey('cleantimeProfiles'),
        isFalse,
      );
    });

    test('views compare by value', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
      );
      await open(harness);
      final view = viewOf(harness);
      expect(view, view.withProfiles(profiles: view.profiles));
      expect(
        view.hashCode,
        view.withProfiles(profiles: view.profiles).hashCode,
      );
      expect(
        const YearsAmount(years: YearCount(1)).hashCode,
        const YearsAmount(years: YearCount(1)).hashCode,
      );
      expect(
        const MonthsAmount(months: MonthCount(1)).hashCode,
        const MonthsAmount(months: MonthCount(1)).hashCode,
      );
      expect(
        const DaysAmount(days: DayCount(1)).hashCode,
        const DaysAmount(days: DayCount(1)).hashCode,
      );
    });
  });

  group('CleantimeHomeController', () {
    Future<HomeCleantime> homeOf(TestContainer harness) async {
      final subscription = harness.container.listen(
        cleantimeHomeProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await flush();
      return switch (harness.read(cleantimeHomeProvider)) {
        Loaded(:final value) => value,
        Loading() || Failed() => throw StateError('not loaded'),
      };
    }

    test('no stored profiles means no cards and no default', () async {
      final harness = cleantimeHarness();
      expect(await homeOf(harness), isA<NoHomeProfiles>());
      expect(
        harness.storage.snapshot.containsKey('cleantimeProfiles'),
        isFalse,
      );
    });

    test('stored profiles become cards', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
        ),
      );
      final home = await homeOf(harness);
      expect(
        home,
        HomeProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
          today: september10,
        ),
      );
      expect(home.hashCode, isA<int>());
    });
  });

  group('CleantimeTexts', () {
    const texts = CleantimeTexts.of;

    test('units switch between singular and plural', () {
      final english = texts(language: Language.english);
      expect(english.years(years: const YearCount(1)).text, '1 year');
      expect(english.months(months: const MonthCount(2)).text, '2 months');
      expect(english.days(days: const DayCount(1)).text, '1 day');
      expect(
        english.anniversaryText(anniversary: Anniversary.fixed[4]).text,
        '6 months',
      );
      expect(
        english.anniversaryText(anniversary: Anniversary.fixed[6]).text,
        '1 year',
      );
      expect(
        english
            .homeBreakdown(
              breakdown: const YearsMonthsDays(
                years: YearCount(6),
                months: MonthCount(4),
                days: DayCount(7),
              ),
            )
            .text,
        '6 years, 4 months, 7 days',
      );
    });
  });
}
