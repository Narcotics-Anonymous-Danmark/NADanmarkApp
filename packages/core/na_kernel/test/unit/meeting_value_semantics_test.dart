@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

final Uri link = Uri.parse('https://zoom.example/j/1');

List<(Object, Object)> copies() => [
  (const InPerson(), const InPerson()),
  (Virtual(link: link), Virtual(link: link)),
  (Hybrid(link: link), Hybrid(link: link)),
  (OpenDirections(uri: link), OpenDirections(uri: link)),
  (JoinVirtualMeeting(uri: link), JoinVirtualMeeting(uri: link)),
  (CallDialIn(uri: link), CallDialIn(uri: link)),
  (aMeeting().times, aMeeting().times),
  (
    const Mapped(point: GeoPoint(latitude: 1, longitude: 2)),
    const Mapped(point: GeoPoint(latitude: 1, longitude: 2)),
  ),
  (const Unmapped(), const Unmapped()),
  (VirtualLinkAt(uri: link), VirtualLinkAt(uri: link)),
  (const NoVirtualLink(), const NoVirtualLink()),
  (const DialInNumber(number: '1'), const DialInNumber(number: '1')),
  (const NoDialIn(), const NoDialIn()),
  (const Comment(text: 'x'), const Comment(text: 'x')),
  (const NoComment(), const NoComment()),
  (
    const TransitLine(kind: TransitKind.bus, lines: '5'),
    const TransitLine(kind: TransitKind.bus, lines: '5'),
  ),
  (
    const MeetingFormatCodes(keys: [FormatKey('O')], sharedIds: []),
    const MeetingFormatCodes(keys: [FormatKey('O')], sharedIds: []),
  ),
  (
    DaySection(weekday: Weekday.monday, meetings: [aMeeting()]),
    DaySection(weekday: Weekday.monday, meetings: [aMeeting()]),
  ),
  (const AllDays(), const AllDays()),
  (
    const OnlyDay(weekday: Weekday.friday),
    const OnlyDay(weekday: Weekday.friday),
  ),
  (const HourRange(lower: 1, upper: 2), const HourRange(lower: 1, upper: 2)),
  (const NoDescription(), const NoDescription()),
  (const Described(text: 'd'), const Described(text: 'd')),
  (
    MeetingFormat.fromRow(row: aFormatRow()),
    MeetingFormat.fromRow(row: aFormatRow()),
  ),
  (
    FormatsSnapshot(
      fetchedAt: Instant(DateTime.utc(2026)),
      rows: [aFormatRow()],
    ),
    FormatsSnapshot(
      fetchedAt: Instant(DateTime.utc(2026)),
      rows: [aFormatRow()],
    ),
  ),
  (
    const ImportFormatsCache(encoded: '{}'),
    const ImportFormatsCache(encoded: '{}'),
  ),
  (const SkipFormatsCache(), const SkipFormatsCache()),
  (
    const NamedMunicipality(name: MunicipalityName('Aarhus')),
    const NamedMunicipality(name: MunicipalityName('Aarhus')),
  ),
  (const OnlineMunicipality(), const OnlineMunicipality()),
];

void main() {
  test(
    'every meeting value equals its copy, hashes alike and describes itself',
    () {
      for (final (value, copy) in copies()) {
        expect(value, copy, reason: '${value.runtimeType}');
        expect(value.hashCode, copy.hashCode, reason: '${value.runtimeType}');
        expect(value.toString(), isNotEmpty);
      }
    },
  );

  test('values of different types never compare equal', () {
    final values = copies().map((pair) => pair.$1).toList();
    expect(values.toSet(), hasLength(values.length));
  });

  test('no TC with a virtual link is open', () {
    expect(
      aMeeting(virtualLink: aVirtualLink()).closure,
      TemporaryClosure.open,
    );
  });

  test('symbols beyond the Latin letters sort after å', () {
    expect(
      const DanishCollation().compare(left: '€', right: 'å'),
      1,
    );
  });
}
