@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const CalendarMapper mapper = CalendarMapper();

extension type const Body(String json) {}

extension type const Raw(String json) {}

Outcome<List<CalendarEvent>, DecodeFailure> decoded(Body body) =>
    mapper.events(json: jsonDecode(body.json));

List<CalendarEvent> eventsOf(Body body) => switch (decoded(body)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$error'),
};

Body row({
  Raw date = const Raw('"2026-10-03"'),
  Raw time = const Raw('"19:30:00"'),
  Raw thumbnail = const Raw('""'),
  Raw url = const Raw('"https://nadanmark.dk/event/x"'),
}) => Body(
  '{"event_name": " Konvent ", "event_start_date": ${date.json}, '
  '"event_start_time": ${time.json}, "location_town": "Aarhus ", '
  '"thumbnail": ${thumbnail.json}, "url": ${url.json}}',
);

Body rows(List<Body> items) =>
    Body('[${items.map((item) => item.json).join(',')}]');

void main() {
  group('CalendarMapper', () {
    test('a full row maps to a calendar event', () {
      expect(
        eventsOf(rows([row(thumbnail: const Raw('"https://img.test/k.jpg"'))])),
        [
          CalendarEvent(
            name: const EventName('Konvent'),
            town: const EventTown('Aarhus'),
            date: const LocalDate(year: 2026, month: 10, day: 3),
            start: const StartsAt(
              time: LocalTime(hour: HourOfDay(19), minute: MinuteOfHour(30)),
            ),
            thumbnail: ThumbnailAt(
              url: ThumbnailUrl(Uri.parse('https://img.test/k.jpg')),
            ),
            page: EventPageUrl(Uri.parse('https://nadanmark.dk/event/x')),
          ),
        ],
      );
    });

    final starts = <(Raw, EventStart)>[
      (const Raw('""'), const NoStartTime()),
      (const Raw('null'), const NoStartTime()),
      (const Raw('"later"'), const NoStartTime()),
      (const Raw('"25:00:00"'), const NoStartTime()),
      (
        const Raw('"09:05"'),
        const StartsAt(
          time: LocalTime(hour: HourOfDay(9), minute: MinuteOfHour(5)),
        ),
      ),
    ];
    for (final (time, start) in starts) {
      test('start time ${time.json} reads as $start', () {
        expect(eventsOf(rows([row(time: time)])).single.start, start);
      });
    }

    for (final thumbnail in const [
      Raw('""'),
      Raw('null'),
      Raw('"img.jpg"'),
      Raw('"ftp://x.test/a"'),
    ]) {
      test('thumbnail ${thumbnail.json} reads as none', () {
        expect(
          eventsOf(rows([row(thumbnail: thumbnail)])).single.thumbnail,
          const NoThumbnail(),
        );
      });
    }

    test('rows without a valid date or page URL are skipped', () {
      final events = eventsOf(
        rows([
          row(url: const Raw('"https://nadanmark.dk/event/a"')),
          row(date: const Raw('"soon"')),
          row(date: const Raw('"2026-02-30"')),
          row(url: const Raw('""')),
          row(url: const Raw('"/event/relative"')),
          const Body('"not an object"'),
          row(url: const Raw('"https://nadanmark.dk/event/b"')),
        ]),
      );
      expect(events.map((event) => event.page.uri.path), [
        '/event/a',
        '/event/b',
      ]);
    });

    test('numbers in text fields are read leniently', () {
      final events = eventsOf(
        const Body(
          '[{"event_name": 2027, "event_start_date": "2027-01-01", '
          '"url": "https://nadanmark.dk/e"}]',
        ),
      );
      expect(events.single.name, const EventName('2027'));
      expect(events.single.town, const EventTown(''));
    });

    test('an empty object is an empty feed and other shapes fail', () {
      expect(eventsOf(const Body('{}')), isEmpty);
      expect(
        decoded(const Body('{"code": "x"}')),
        isA<Err<List<CalendarEvent>, DecodeFailure>>(),
      );
      expect(
        decoded(const Body('"text"')),
        isA<Err<List<CalendarEvent>, DecodeFailure>>(),
      );
    });

    test('the DTO writes snake case keys', () {
      expect(
        const CalendarEventDto(
          eventName: 'A',
          eventStartDate: '2026-01-01',
        ).toJson(),
        {'event_name': 'A', 'event_start_date': '2026-01-01'},
      );
    });
  });

  group('LocalTime.parseClock', () {
    test('reads hours with optional minutes and seconds', () {
      expect(
        LocalTime.parseClock(text: '19:30:00'),
        const Ok<LocalTime, DecodeFailure>(
          value: LocalTime(hour: HourOfDay(19), minute: MinuteOfHour(30)),
        ),
      );
      expect(
        LocalTime.parseClock(text: '7'),
        const Ok<LocalTime, DecodeFailure>(
          value: LocalTime(hour: HourOfDay(7), minute: MinuteOfHour(0)),
        ),
      );
    });

    test('rejects out of range and non-numeric times', () {
      for (final text in const [
        Raw(''),
        Raw('x'),
        Raw('24:00'),
        Raw('12:60'),
        Raw('-1:00'),
        Raw('12:xx'),
      ]) {
        expect(
          LocalTime.parseClock(text: text.json),
          isA<Err<LocalTime, DecodeFailure>>(),
        );
      }
    });
  });
}
