@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

JftEntry entry({required int day, required DanishMonth month}) => JftEntry(
  day: day,
  month: month,
  title: 'Title $day/${month.number}',
  quote: 'Quote',
  source: 'Source',
  text: 'Text',
  closing: JftClosing.parse(text: 'Bare for i dag: body'),
);

List<JftEntry> wholeYear() => List.unmodifiable(
  DanishMonth.values.expand(
    (month) => List.generate(
      month.daysInLeapYear,
      (index) => entry(day: index + 1, month: month),
    ),
  ),
);

void main() {
  group('JftCalendar', () {
    test('a full year has 366 entries and no missing days', () {
      final calendar = JftCalendar(entries: wholeYear());
      expect(calendar.entries, hasLength(JftCalendar.expectedEntryCount));
      expect(calendar.missingDays, isEmpty);
    });

    test('selects the entry for the calendar day', () {
      final calendar = JftCalendar(entries: wholeYear());
      final lookup = calendar.entryFor(
        date: const LocalDate(year: 2026, month: 5, day: 3),
      );
      expect(lookup, JftFound(entry: entry(day: 3, month: DanishMonth.maj)));
    });

    test('selects the leap day entry', () {
      final calendar = JftCalendar(entries: wholeYear());
      final lookup = calendar.entryFor(
        date: const LocalDate(year: 2028, month: 2, day: 29),
      );
      expect(
        lookup,
        JftFound(entry: entry(day: 29, month: DanishMonth.februar)),
      );
    });

    test('reports missing and duplicated days', () {
      final entries = wholeYear().where((e) => e.day != 1).toList()
        ..add(entry(day: 2, month: DanishMonth.januar));
      final calendar = JftCalendar(entries: entries);
      expect(calendar.missingDays, contains('1. januar'));
      expect(calendar.missingDays, contains('2. januar'));
      expect(calendar.missingDays, contains('1. december'));
      expect(
        calendar.entryFor(date: const LocalDate(year: 2026, month: 1, day: 1)),
        const JftMissing(date: LocalDate(year: 2026, month: 1, day: 1)),
      );
    });
  });

  group('JftClosing', () {
    test('splits the Danish lead from the body', () {
      final closing = JftClosing.parse(text: 'Bare for i dag: Jeg vil.');
      expect(closing, const JftClosingWithLead(body: 'Jeg vil.'));
      expect(closing.fullText, 'Bare for i dag: Jeg vil.');
    });

    test('keeps text without the lead as plain', () {
      final closing = JftClosing.parse(text: 'Noget andet');
      expect(closing, const JftClosingPlain(body: 'Noget andet'));
      expect(closing.fullText, 'Noget andet');
    });
  });

  group('DanishMonth', () {
    test('parses names and maps numbers', () {
      expect(
        DanishMonth.parse(name: 'maj'),
        const Ok<DanishMonth, DecodeFailure>(value: DanishMonth.maj),
      );
      expect(
        DanishMonth.parse(name: 'may'),
        isA<Err<DanishMonth, DecodeFailure>>(),
      );
      expect(DanishMonth.ofNumber(number: 12), DanishMonth.december);
      expect(entry(day: 1, month: DanishMonth.januar).dateLabel, '1. januar');
    });
  });
}
