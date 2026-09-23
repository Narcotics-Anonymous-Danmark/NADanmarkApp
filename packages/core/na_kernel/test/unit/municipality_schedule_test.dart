@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

const schedule = MeetingSchedule();

List<MunicipalityName> names(List<String> raw) =>
    List.unmodifiable(raw.map(MunicipalityName.new));

void main() {
  group('Municipalities', () {
    test('rows are unique in server order and Online is last', () {
      expect(
        Municipality.directory(
          names: names([
            'Aarhus',
            'Aarhus',
            'København',
            '',
            'Online møde',
            'Viborg.',
          ]),
        ).map((m) => m.toString()),
        ['Aarhus', 'København', 'Online'],
      );
    });

    test('every online alias normalises to Online', () {
      for (final alias in [
        '',
        '  ',
        'Online møde',
        'Viborg online',
        'Viborg.',
      ]) {
        expect(
          Municipality.normalise(raw: MunicipalityName(alias)),
          const OnlineMunicipality(),
        );
      }
    });

    test('other names are trimmed and kept', () {
      expect(
        Municipality.normalise(raw: const MunicipalityName(' Viborg ')),
        const NamedMunicipality(name: MunicipalityName('Viborg')),
      );
    });
  });

  group('Weekday grouping and ordering', () {
    final meetings = [
      aMeeting(id: 1, weekday: Weekday.sunday, hour: 11),
      aMeeting(id: 2, weekday: Weekday.monday, hour: 19),
      aMeeting(id: 3, weekday: Weekday.monday, hour: 17, minute: 30),
      aMeeting(id: 4, weekday: Weekday.monday, hour: 19),
    ];

    test('Monday first moves Sunday to the end', () {
      expect(
        schedule
            .group(meetings: meetings, firstDay: FirstDayOfWeek.monday)
            .map((section) => section.weekday),
        [Weekday.monday, Weekday.sunday],
      );
    });

    test('Sunday first keeps Sunday at the start', () {
      expect(
        schedule
            .group(meetings: meetings, firstDay: FirstDayOfWeek.sunday)
            .map((section) => section.weekday),
        [Weekday.sunday, Weekday.monday],
      );
    });

    test(
      'a day is sorted by start time, ties in server order, with a count',
      () {
        final monday = schedule
            .group(meetings: meetings, firstDay: FirstDayOfWeek.monday)
            .first;
        expect(monday.meetings.map((meeting) => meeting.id.value), [3, 2, 4]);
        expect(monday.count, 3);
        expect(monday.toString(), 'monday (3)');
      },
    );

    test('days without meetings get no section', () {
      expect(
        schedule.group(meetings: const [], firstDay: FirstDayOfWeek.monday),
        isEmpty,
      );
    });
  });

  group('Day and hour filters', () {
    final meetings = [
      aMeeting(id: 1, weekday: Weekday.friday, hour: 17, minute: 30),
      aMeeting(id: 2, weekday: Weekday.friday, hour: 18),
      aMeeting(id: 3, weekday: Weekday.friday, hour: 20, minute: 59),
      aMeeting(id: 4, weekday: Weekday.friday, hour: 21),
      aMeeting(id: 5, weekday: Weekday.monday, hour: 19),
    ];

    List<int> ids(List<Meeting> filtered) =>
        filtered.map((meeting) => meeting.id.value).toList();

    test('the day filter keeps one day', () {
      expect(
        ids(
          schedule.filter(
            meetings: meetings,
            day: const OnlyDay(weekday: Weekday.friday),
            hours: HourRange.wholeDay,
          ),
        ),
        [1, 2, 3, 4],
      );
    });

    test('the hour range filters by start hour inclusively', () {
      expect(
        ids(
          schedule.filter(
            meetings: meetings,
            day: const AllDays(),
            hours: const HourRange(lower: 18, upper: 20),
          ),
        ),
        [2, 3, 5],
      );
    });

    test('filtering recomputes the section counts', () {
      final sections = schedule.group(
        meetings: schedule.filter(
          meetings: meetings,
          day: const AllDays(),
          hours: const HourRange(lower: 18, upper: 20),
        ),
        firstDay: FirstDayOfWeek.monday,
      );
      expect(sections.map((section) => section.toString()), [
        'monday (1)',
        'friday (2)',
      ]);
    });

    test('filters and ranges compare by value', () {
      expect(const AllDays(), const AllDays());
      expect(
        const OnlyDay(weekday: Weekday.friday),
        const OnlyDay(weekday: Weekday.friday),
      );
      expect(
        const HourRange(lower: 1, upper: 2),
        const HourRange(lower: 1, upper: 2),
      );
      expect(HourRange.wholeDay.toString(), '0-23');
    });
  });
}
