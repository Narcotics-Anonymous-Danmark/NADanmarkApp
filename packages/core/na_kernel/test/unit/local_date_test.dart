@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

void main() {
  group('LocalDate', () {
    test('adds months clamping to the last day of the target month', () {
      expect(
        aDate(month: 1, day: 31).plusMonths(months: 1),
        aDate(month: 2, day: 28),
      );
    });

    test('adds years over a leap day by clamping to 28 February', () {
      expect(
        aDate(year: 2024, month: 2, day: 29).plusYears(years: 1),
        aDate(year: 2025, month: 2, day: 28),
      );
    });

    test('counts whole months until a later date', () {
      expect(
        aDate(
          month: 1,
          day: 31,
        ).wholeMonthsUntil(other: aDate(month: 3, day: 1)),
        1,
      );
    });

    test('counts whole years like successive floors', () {
      expect(
        aDate(
          year: 2020,
          month: 6,
          day: 15,
        ).wholeYearsUntil(other: aDate(year: 2026, month: 6, day: 14)),
        5,
      );
    });

    test('knows its weekday', () {
      expect(aDate(year: 2026, month: 9, day: 13).weekday, Weekday.sunday);
    });

    test('computes day of year', () {
      expect(aDate(year: 2026, month: 12, day: 31).dayOfYear, 365);
    });

    test('compares dates', () {
      expect(
        aDate(day: 1).compareTo(other: aDate(day: 2)),
        Comparison.before,
      );
      expect(aDate().compareTo(other: aDate()), Comparison.same);
    });

    test('formats as ISO 8601', () {
      expect(aDate(year: 2026, month: 1, day: 5).iso8601, '2026-01-05');
    });
  });
}
