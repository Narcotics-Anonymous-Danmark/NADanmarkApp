@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

final Uri link = Uri.parse('https://zoom.example/j/1');

void expectValueSemantics<T>({
  required T Function() build,
  required T different,
}) {
  expect(build(), build());
  expect(build().hashCode, build().hashCode);
  expect(build().toString(), isNotEmpty);
  expect(build(), isNot(different));
}

void main() {
  group('Venues and actions', () {
    test('venues compare by value', () {
      expectValueSemantics<MeetingVenue>(
        build: () => const InPerson(),
        different: Virtual(link: link),
      );
      expectValueSemantics<MeetingVenue>(
        build: () => Virtual(link: link),
        different: Hybrid(link: link),
      );
      expectValueSemantics<MeetingVenue>(
        build: () => Hybrid(link: link),
        different: const InPerson(),
      );
    });

    test('actions compare by value', () {
      expectValueSemantics<MeetingAction>(
        build: () => OpenDirections(uri: link),
        different: JoinVirtualMeeting(uri: link),
      );
      expectValueSemantics<MeetingAction>(
        build: () => JoinVirtualMeeting(uri: link),
        different: CallDialIn(uri: link),
      );
      expectValueSemantics<MeetingAction>(
        build: () => CallDialIn(uri: link),
        different: OpenDirections(uri: link),
      );
    });
  });

  group('Meeting parts', () {
    test('times compare by value', () {
      expectValueSemantics<MeetingTimes>(
        build: () => aMeeting().times,
        different: aMeeting(hour: 7).times,
      );
    });

    test('locations compare by value', () {
      expectValueSemantics<MeetingLocation>(
        build: () => const Mapped(
          point: GeoPoint(latitude: Latitude(1), longitude: Longitude(2)),
        ),
        different: const Unmapped(),
      );
      expectValueSemantics<MeetingLocation>(
        build: () => const Unmapped(),
        different: const Mapped(
          point: GeoPoint(latitude: Latitude(1), longitude: Longitude(2)),
        ),
      );
    });

    test('virtual links compare by value', () {
      expectValueSemantics<VirtualLink>(
        build: () => VirtualLinkAt(uri: link),
        different: const NoVirtualLink(),
      );
      expectValueSemantics<VirtualLink>(
        build: () => const NoVirtualLink(),
        different: VirtualLinkAt(uri: link),
      );
    });

    test('dial-ins compare by value', () {
      expectValueSemantics<DialIn>(
        build: () => const DialInNumber(number: PhoneNumber('1')),
        different: const NoDialIn(),
      );
      expectValueSemantics<DialIn>(
        build: () => const NoDialIn(),
        different: const DialInNumber(number: PhoneNumber('1')),
      );
    });

    test('comments compare by value', () {
      expectValueSemantics<MeetingComment>(
        build: () => const Comment(text: CommentText('x')),
        different: const NoComment(),
      );
      expectValueSemantics<MeetingComment>(
        build: () => const NoComment(),
        different: const Comment(text: CommentText('x')),
      );
    });

    test('transit lines compare by value', () {
      expectValueSemantics<TransitLine>(
        build: () => const TransitLine(
          kind: TransitKind.bus,
          lines: TransitLines('5'),
        ),
        different: const TransitLine(
          kind: TransitKind.train,
          lines: TransitLines('5'),
        ),
      );
    });

    test('format codes compare by value', () {
      expectValueSemantics<MeetingFormatCodes>(
        build: () => const MeetingFormatCodes(
          keys: [FormatKey('O')],
          sharedIds: [],
        ),
        different: MeetingFormatCodes.none,
      );
    });

    test('municipalities compare by value', () {
      expectValueSemantics<Municipality>(
        build: () => const NamedMunicipality(name: MunicipalityName('Aarhus')),
        different: const OnlineMunicipality(),
      );
      expectValueSemantics<Municipality>(
        build: () => const OnlineMunicipality(),
        different: const NamedMunicipality(name: MunicipalityName('Aarhus')),
      );
    });
  });

  group('Schedule', () {
    test('day sections compare by value', () {
      expectValueSemantics<DaySection>(
        build: () =>
            DaySection(weekday: Weekday.monday, meetings: [aMeeting()]),
        different: DaySection(weekday: Weekday.friday, meetings: [aMeeting()]),
      );
    });

    test('day filters compare by value', () {
      expectValueSemantics<DayFilter>(
        build: () => const AllDays(),
        different: const OnlyDay(weekday: Weekday.friday),
      );
      expectValueSemantics<DayFilter>(
        build: () => const OnlyDay(weekday: Weekday.friday),
        different: const AllDays(),
      );
    });

    test('hour ranges compare by value', () {
      expectValueSemantics<HourRange>(
        build: () => const HourRange(lower: HourOfDay(1), upper: HourOfDay(2)),
        different: HourRange.wholeDay,
      );
    });
  });

  group('Formats', () {
    test('descriptions compare by value', () {
      expectValueSemantics<FormatDescription>(
        build: () => const Described(text: FormatDescriptionText('d')),
        different: const NoDescription(),
      );
      expectValueSemantics<FormatDescription>(
        build: () => const NoDescription(),
        different: const Described(text: FormatDescriptionText('d')),
      );
    });

    test('formats and snapshots compare by value', () {
      expectValueSemantics<MeetingFormat>(
        build: () => MeetingFormat.fromRow(row: aFormatRow()),
        different: MeetingFormat.fromRow(row: aFormatRow(key: 'X')),
      );
      expectValueSemantics<FormatsSnapshot>(
        build: () => FormatsSnapshot(
          fetchedAt: Instant(DateTime.utc(2026)),
          rows: [aFormatRow()],
        ),
        different: FormatsSnapshot(
          fetchedAt: Instant(DateTime.utc(2025)),
          rows: [aFormatRow()],
        ),
      );
    });

    test('legacy cache imports compare by value', () {
      expectValueSemantics<LegacyFormatsImport>(
        build: () => ImportFormatsCache(
          snapshot: FormatsSnapshot(
            fetchedAt: Instant(DateTime.utc(2026)),
            rows: [aFormatRow()],
          ),
        ),
        different: const SkipFormatsCache(),
      );
      expectValueSemantics<LegacyFormatsImport>(
        build: () => const SkipFormatsCache(),
        different: ImportFormatsCache(
          snapshot: FormatsSnapshot(
            fetchedAt: Instant(DateTime.utc(2026)),
            rows: const [],
          ),
        ),
      );
    });
  });

  test('no TC with a virtual link is open', () {
    expect(
      aMeeting(virtualLink: aVirtualLink()).closure,
      TemporaryClosure.open,
    );
  });
}
