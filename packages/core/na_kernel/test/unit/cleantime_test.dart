@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

const ProfileName anna = ProfileName('Anna');
const ProfileName bo = ProfileName('Bo');
const ProfileName carl = ProfileName('Carl');

CleantimeProfile aProfile({
  ProfileName name = anna,
  LocalDate cleanDate = const LocalDate(year: 2020, month: 5, day: 3),
}) => CleantimeProfile(name: name, cleanDate: cleanDate);

final CleantimeProfile fallback = aProfile(
  name: const ProfileName('Profile 1'),
  cleanDate: aDate(),
);

CleantimeProfiles profilesOf({
  required List<ProfileName> names,
  ProfileIndex active = const ProfileIndex(0),
}) => CleantimeProfiles.restore(
  entries: List.unmodifiable(names.map((name) => aProfile(name: name))),
  active: active,
  fallback: fallback,
);

List<ProfileName> namesOf({required CleantimeProfiles profiles}) =>
    List.unmodifiable(profiles.entries.map((profile) => profile.name));

CleanTime cleanTimeOf({
  required YearCount years,
  required MonthCount months,
  required DayCount days,
  required MonthCount allMonths,
  required DayCount monthDays,
  required DayCount totalDays,
}) => CleanTime(
  yearsMonthsDays: YearsMonthsDays(years: years, months: months, days: days),
  monthsDays: MonthsDays(months: allMonths, days: monthDays),
  days: totalDays,
);

void main() {
  group('CleantimeProfiles', () {
    test('restoring nothing creates the fallback profile', () {
      final profiles = CleantimeProfiles.restore(
        entries: const [],
        active: const ProfileIndex(3),
        fallback: fallback,
      );
      expect(profiles.entries, [fallback]);
      expect(profiles.active, const ProfileIndex(0));
    });

    test('restoring clamps the active index', () {
      expect(
        profilesOf(names: [anna, bo], active: const ProfileIndex(7)).active,
        const ProfileIndex(1),
      );
      expect(
        profilesOf(names: [anna, bo], active: const ProfileIndex(-2)).active,
        const ProfileIndex(0),
      );
    });

    test('adding appends and selects the new profile', () {
      final profiles = profilesOf(
        names: [anna],
      ).add(profile: aProfile(name: bo));
      expect(namesOf(profiles: profiles), [anna, bo]);
      expect(profiles.activeProfile.name, bo);
    });

    test('renaming keeps the clean date', () {
      final profiles = profilesOf(
        names: [anna, bo],
        active: const ProfileIndex(1),
      ).rename(name: carl);
      expect(namesOf(profiles: profiles), [anna, carl]);
      expect(profiles.activeProfile.cleanDate, aProfile().cleanDate);
    });

    test('changing the date touches only the active profile', () {
      final profiles = profilesOf(
        names: [anna, bo],
      ).changeDate(cleanDate: aDate(year: 2020, month: 1, day: 15));
      expect(
        profiles.entries.first.cleanDate,
        aDate(year: 2020, month: 1, day: 15),
      );
      expect(profiles.entries.last.cleanDate, aProfile().cleanDate);
    });

    test('selecting clamps to the list', () {
      expect(
        profilesOf(
          names: [anna, bo],
        ).select(index: const ProfileIndex(9)).active,
        const ProfileIndex(1),
      );
    });

    test('deleting removes the active profile and selects the first', () {
      final profiles = profilesOf(
        names: [anna, bo, carl],
        active: const ProfileIndex(2),
      ).deleteActive(fallback: fallback);
      expect(namesOf(profiles: profiles), [anna, bo]);
      expect(profiles.active, const ProfileIndex(0));
    });

    test('deleting the last profile recreates the fallback', () {
      expect(
        profilesOf(names: [anna]).deleteActive(fallback: fallback).entries,
        [fallback],
      );
    });

    test('names are trimmed on request', () {
      expect(const ProfileName('  Bo ').trimmed, bo);
    });

    test('profiles compare by value', () {
      expect(profilesOf(names: [anna]), profilesOf(names: [anna]));
      expect(
        profilesOf(names: [anna]).hashCode,
        profilesOf(names: [anna]).hashCode,
      );
      expect(profilesOf(names: [anna]), isNot(profilesOf(names: [bo])));
      expect(aProfile().toString(), contains(anna));
      expect(profilesOf(names: [anna]).toString(), contains(anna));
    });
  });

  group('CleanTime', () {
    test('breakdown for a known date', () {
      expect(
        CleanTime.between(
          cleanDate: aDate(year: 2023, month: 1, day: 31),
          today: aDate(year: 2026, month: 3, day: 1),
        ),
        cleanTimeOf(
          years: const YearCount(3),
          months: const MonthCount(1),
          days: const DayCount(1),
          allMonths: const MonthCount(37),
          monthDays: const DayCount(1),
          totalDays: const DayCount(1125),
        ),
      );
    });

    test('month-end clean date', () {
      expect(
        CleanTime.between(
          cleanDate: aDate(year: 2023, month: 8, day: 31),
          today: aDate(year: 2024, month: 2, day: 29),
        ).yearsMonthsDays,
        const YearsMonthsDays(
          years: YearCount(0),
          months: MonthCount(6),
          days: DayCount(0),
        ),
      );
    });

    test('a clean date after today counts as today', () {
      expect(
        CleanTime.between(
          cleanDate: aDate(day: 12),
          today: aDate(),
        ),
        cleanTimeOf(
          years: const YearCount(0),
          months: const MonthCount(0),
          days: const DayCount(0),
          allMonths: const MonthCount(0),
          monthDays: const DayCount(0),
          totalDays: const DayCount(0),
        ),
      );
    });

    test('values describe themselves', () {
      final cleanTime = CleanTime.between(
        cleanDate: aDate(year: 2020, month: 5, day: 3),
        today: aDate(),
      );
      expect(cleanTime.toString(), contains('6, 4, 7'));
      expect(
        cleanTime.hashCode,
        CleanTime.between(
          cleanDate: aDate(year: 2020, month: 5, day: 3),
          today: aDate(),
        ).hashCode,
      );
      expect(cleanTime.monthsDays.toString(), contains('76'));
    });
  });

  group('AnniversaryToday', () {
    test('one year shows the year tag', () {
      expect(
        AnniversaryToday.of(cleanDate: aDate(year: 2025), today: aDate()),
        const OnAnniversary(
          anniversary: Anniversary(
            kind: AnniversaryKind.oneYear,
            offset: AfterYears(years: YearCount(1)),
          ),
        ),
      );
    });

    test('multi-year anniversary', () {
      expect(
        AnniversaryToday.of(cleanDate: aDate(year: 2021), today: aDate()),
        OnAnniversary(
          anniversary: Anniversary.afterYears(years: const YearCount(5)),
        ),
      );
      expect(AnniversaryKind.years.keyTag, const KeyTagName('x-years'));
    });

    test('day anniversaries', () {
      expect(
        AnniversaryToday.of(cleanDate: aDate(day: 9), today: aDate()),
        const OnAnniversary(
          anniversary: Anniversary(
            kind: AnniversaryKind.oneDay,
            offset: AfterDays(days: DayCount(1)),
          ),
        ),
      );
    });

    test('no anniversary', () {
      expect(
        AnniversaryToday.of(
          cleanDate: aDate().plusDays(days: -45),
          today: aDate(),
        ),
        const NoAnniversary(),
      );
      expect(
        AnniversaryToday.of(cleanDate: aDate(day: 12), today: aDate()),
        const NoAnniversary(),
      );
    });
  });

  group('UpcomingAnniversary', () {
    List<String> upcomingFor({required LocalDate cleanDate}) =>
        List.unmodifiable(
          UpcomingAnniversary.within(
            cleanDate: cleanDate,
            today: aDate(),
          ).map((upcoming) => upcoming.anniversary.offset.toString()),
        );

    test('window for a recent clean date', () {
      expect(upcomingFor(cleanDate: aDate().plusDays(days: -10)), [
        '30 days',
        '60 days',
        '90 days',
        '6 months',
        '9 months',
        '1 years',
        '18 months',
        '2 years',
      ]);
    });

    test('window for an old clean date', () {
      expect(
        upcomingFor(
          cleanDate: aDate().plusYears(years: -4).plusDays(days: -200),
        ),
        ['5 years', '6 years'],
      );
    });

    test('a clean date after the window has no anniversaries', () {
      expect(upcomingFor(cleanDate: aDate(year: 2030)), isEmpty);
    });

    test('values compare and describe themselves', () {
      final first = UpcomingAnniversary.within(
        cleanDate: aDate(day: 1),
        today: aDate(),
      ).first;
      expect(
        first,
        UpcomingAnniversary.within(
          cleanDate: aDate(day: 1),
          today: aDate(),
        ).first,
      );
      expect(first.hashCode, isA<int>());
      expect(first.toString(), contains('thirtyDays'));
      expect(const NoAnniversary().toString(), 'NoAnniversary()');
      expect(const NoAnniversary().hashCode, const NoAnniversary().hashCode);
      expect(
        const AfterDays(days: DayCount(1)),
        isNot(const AfterMonths(months: MonthCount(1))),
      );
    });
  });
}
