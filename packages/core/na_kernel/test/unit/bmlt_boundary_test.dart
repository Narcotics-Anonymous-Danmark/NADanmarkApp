@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

const codec = FormatsCacheCodec();
const legacy = LegacyMeetingFormatsTranslator();

Meeting meetingFrom({required BmltMeetingDto dto}) =>
    switch (mapper.meeting(dto: dto)) {
      Ok(:final value) => value,
      Err(:final error) => fail('$error'),
    };

void main() {
  group('BMLT meeting rows', () {
    test('a recorded in-person meeting decodes every field', () {
      final meeting = recordedMeetings().first;
      expect(meeting.id, const MeetingId(115));
      expect(meeting.name, const MeetingName('Traditionerne tro'));
      expect(meeting.weekday, Weekday.sunday);
      expect(meeting.times.toString(), '11:00 - 12:00');
      expect(meeting.formatCodes.keys, hasLength(6));
      expect(meeting.formatCodes.sharedIds.first, const FormatId(4));
      expect(meeting.origin, MeetingOrigin.denmark);
      expect(
        meeting.location,
        const Mapped(
          point: GeoPoint(
            latitude: Latitude(55.6201832),
            longitude: Longitude(8.4830404),
          ),
        ),
      );
      expect(meeting.venue, const InPerson());
      expect(meeting.locationLines, isNotEmpty);
    });

    test('a recorded virtual meeting has a link and belongs to Online', () {
      final meeting = recordedMeetings()[1];
      expect(
        meeting.virtualLink,
        aVirtualLink(url: 'https://zoom.example/j/123456789'),
      );
      expect(meeting.venue, isA<Virtual>());
      expect(meeting.municipality, const OnlineMunicipality());
      expect(meeting.locationLines, isEmpty);
    });

    test('a recorded bus line loses its BMLT prefix', () {
      expect(recordedMeetings()[2].transitLines, [
        const TransitLine(
          kind: TransitKind.bus,
          lines: TransitLines('Dørene åbnes KL.16:00'),
        ),
      ]);
    });

    test('values are trimmed and blank values are absent', () {
      final meeting = meetingFrom(
        dto: const BmltMeetingDto(
          idBigint: '7',
          weekdayTinyint: '2',
          startTime: '19:00:00',
          durationTime: '',
          meetingName: '  Møde  ',
          locationStreet: '  ',
          locationPostalCode1: ' 8000 ',
          comments: ' Husk ',
          phoneMeetingNumber: ' ',
          rootServerUri: 'https://tomato.example',
          latitude: '0',
          longitude: '0',
        ),
      );
      expect(meeting.name, const MeetingName('Møde'));
      expect(meeting.locationLines, [const LocationLine('8000')]);
      expect(meeting.comment, const Comment(text: CommentText('Husk')));
      expect(meeting.dialIn, const NoDialIn());
      expect(meeting.duration, Duration.zero);
      expect(meeting.origin, MeetingOrigin.otherRoot);
      expect(meeting.location, const Unmapped());
      expect(meeting.municipality, const OnlineMunicipality());
    });

    test('a root server id marks an aggregated Danish meeting', () {
      final meeting = meetingFrom(
        dto: const BmltMeetingDto(
          idBigint: '8',
          weekdayTinyint: '1',
          startTime: '10:00',
          rootServerUri: 'https://www.nadanmark.dk/main_server',
          rootServerId: '12',
          phoneMeetingNumber: '+45 1',
        ),
      );
      expect(meeting.origin, MeetingOrigin.denmarkAggregated);
      expect(
        meeting.dialIn,
        const DialInNumber(number: PhoneNumber('+45 1')),
      );
    });

    test('numbers on the wire are read as text', () {
      final dtos = wire.rows(
        json: [
          {'id_bigint': 9, 'weekday_tinyint': 3, 'start_time': '08:00'},
        ],
        fromJson: BmltMeetingDto.fromJson,
        context: 'meetings',
      );
      final dto = (dtos as Ok<List<BmltMeetingDto>, DecodeFailure>).value;
      expect(meetingFrom(dto: dto.single).id, const MeetingId(9));
    });

    test('an empty object is no meetings and malformed rows are skipped', () {
      expect(
        (mapper.meetings(json: <String, dynamic>{})
                as Ok<List<Meeting>, DecodeFailure>)
            .value,
        isEmpty,
      );
      final outcome = mapper.meetings(
        json: [
          {'id_bigint': 'x'},
          {'id_bigint': '1', 'weekday_tinyint': '9', 'start_time': '10:00'},
          {'id_bigint': '2', 'weekday_tinyint': '2', 'start_time': '25:00'},
          'not a row',
          {'id_bigint': '3', 'weekday_tinyint': '2', 'start_time': '10:00'},
        ],
      );
      expect(
        (outcome as Ok<List<Meeting>, DecodeFailure>).value.map((m) => m.id),
        [const MeetingId(3)],
      );
    });

    test('anything but a list or an empty object is a decode failure', () {
      expect(
        mapper.meetings(json: 'oops'),
        isA<Err<List<Meeting>, DecodeFailure>>(),
      );
      expect(
        mapper.meetings(json: {'error': 'x'}),
        isA<Err<List<Meeting>, DecodeFailure>>(),
      );
    });

    test('the recorded municipality rows decode in server order', () {
      final names = recordedMunicipalities();
      expect(names, hasLength(168));
      expect(names.first, const MunicipalityName('2300 københavn s'));
    });
  });

  group('Wire helpers', () {
    test('lenient text accepts text and numbers only', () {
      const text = LenientText();
      expect(text.fromJson('a'), 'a');
      expect(text.fromJson(7), '7');
      expect(text.fromJson(40.0), '40');
      expect(text.fromJson(2.5), '2.5');
      expect(text.fromJson(true), isNull);
      expect(text.toJson('a'), 'a');
    });

    test('lenient int accepts integers, whole doubles and digits', () {
      const number = LenientInt();
      expect(number.fromJson(3), 3);
      expect(number.fromJson(4.0), 4);
      expect(number.fromJson(' 5 '), 5);
      expect(number.fromJson(4.5), isNull);
      expect(number.fromJson('x'), isNull);
      expect(number.toJson(6), 6);
    });

    test('a strict list needs every row to decode', () {
      expect(
        wire.list(
          json: [
            {'id': '1'},
          ],
          fromJson: BmltFormatDto.fromJson,
          context: 'x',
        ),
        isA<Ok<List<BmltFormatDto>, DecodeFailure>>(),
      );
      for (final json in <Object?>[
        <Object?>[],
        <String, Object?>{},
        [
          {'id': '1'},
          3,
        ],
      ]) {
        expect(
          wire.list(json: json, fromJson: BmltFormatDto.fromJson, context: 'x'),
          isA<Err<List<BmltFormatDto>, DecodeFailure>>(),
          reason: '$json',
        );
      }
    });

    test('malformed text and wrong shapes are decode failures', () {
      expect(
        wire.parse(text: '{', context: 'x'),
        isA<Err<Object?, DecodeFailure>>(),
      );
      expect(
        wire.object(json: 3, fromJson: BmltFormatDto.fromJson, context: 'x'),
        isA<Err<BmltFormatDto, DecodeFailure>>(),
      );
      expect(
        wire.object(
          json: {'formats': 'not a list'},
          fromJson: FormatsCacheDto.fromJson,
          context: 'x',
        ),
        isA<Err<FormatsCacheDto, DecodeFailure>>(),
      );
    });
  });

  group('GetFormats rows and the cache', () {
    test('the recorded rows decode per language', () {
      final rows = recordedFormatRows();
      expect(
        rows.where((row) => row.language == FormatLanguageCode.danish),
        hasLength(29),
      );
      expect(
        rows.where((row) => row.language == FormatLanguageCode.english),
        hasLength(25),
      );
    });

    test('rows without a numeric id are skipped', () {
      final outcome = mapper.formatRows(
        json: [
          {'key_string': 'A'},
          {'id': 'x', 'key_string': 'B'},
          {'id': 1, 'key_string': 'C'},
        ],
      );
      expect(
        (outcome as Ok<List<FormatRow>, DecodeFailure>).value.single.key,
        const FormatKey('C'),
      );
    });

    test('a snapshot survives an encode and decode round trip unchanged', () {
      final snapshot = FormatsSnapshot(
        fetchedAt: Instant(DateTime.utc(2026, 9, 10, 12)),
        rows: recordedFormatRows(),
      );
      expect(
        codec.decode(text: codec.encode(snapshot: snapshot)),
        Ok<FormatsSnapshot, DecodeFailure>(value: snapshot),
      );
    });

    test('a malformed cache is a decode failure', () {
      for (final text in ['nope', '[]', '{"fetchedAt":"x","formats":[]}']) {
        expect(
          codec.decode(text: text),
          isA<Err<FormatsSnapshot, DecodeFailure>>(),
          reason: text,
        );
      }
    });

    test('a snapshot is fresh for seven days', () {
      final fetchedAt = Instant(DateTime.utc(2026, 9, 10));
      final snapshot = FormatsSnapshot(fetchedAt: fetchedAt, rows: const []);
      expect(
        snapshot.freshnessAt(
          now: fetchedAt.plus(duration: const Duration(days: 3)),
        ),
        SnapshotFreshness.fresh,
      );
      expect(
        snapshot.freshnessAt(
          now: fetchedAt.plus(duration: const Duration(days: 7)),
        ),
        SnapshotFreshness.stale,
      );
    });
  });

  group('Legacy meeting formats cache', () {
    const row = BmltFormatDto(id: '17', keyString: 'ÅM', lang: 'da');

    test('a cache with rows becomes a snapshot', () {
      final import = legacy.translate(
        cache: const FormatsCacheDto(fetchedAt: 1757500000000, formats: [row]),
      );
      final snapshot = (import as ImportFormatsCache).snapshot;
      expect(snapshot.fetchedAt.epochMilliseconds, 1757500000000);
      expect(snapshot.rows.single.key, const FormatKey('ÅM'));
    });

    test('an empty or incomplete cache is skipped', () {
      expect(
        legacy.translate(
          cache: const FormatsCacheDto(fetchedAt: 1, formats: []),
        ),
        const SkipFormatsCache(),
      );
      expect(
        legacy.translate(cache: const FormatsCacheDto(formats: [row])),
        const SkipFormatsCache(),
      );
    });

    test('the dump reads the cache as an object or as a JSON string', () {
      final asObject = LegacyStoreDumpDto.fromJson(const {
        'meeting_formats_v1': {
          'fetchedAt': 1,
          'formats': [
            {'id': '1'},
          ],
        },
        'searchRange': 30,
      });
      final asText = LegacyStoreDumpDto.fromJson(const {
        'meeting_formats_v1': '{"fetchedAt":1,"formats":[{"id":"1"}]}',
      });
      final garbage = LegacyStoreDumpDto.fromJson(const {
        'meeting_formats_v1': 'nope',
      });
      expect(asObject.meetingFormatsV1?.formats, hasLength(1));
      expect(asObject.searchRange, '30');
      expect(asText.meetingFormatsV1?.fetchedAt, 1);
      expect(garbage.meetingFormatsV1, isNull);
      expect(asObject, LegacyStoreDumpDto.fromJson(asObject.toJson()));
      expect(asObject.toString(), contains('meeting_formats_v1'));
    });
  });

  group('Busy events', () {
    test('busy events reach their subscribers', () async {
      final bus = BroadcastEventBus();
      final started = bus.on<BusyStarted>().first;
      final ended = bus.on<BusyEnded>().first;
      bus
        ..publish(
          event: const BusyStarted(activity: BusyActivity.findingMeetings),
        )
        ..publish(
          event: const BusyEnded(activity: BusyActivity.findingMeetings),
        );
      expect((await started).activity, BusyActivity.findingMeetings);
      expect((await ended).activity, BusyActivity.findingMeetings);
      await bus.dispose();
    });

    test('the tracker brackets work with started and ended', () async {
      final bus = BroadcastEventBus();
      final seen = <String>[];
      final subscription = bus.all.listen(
        (event) => seen.add(event.runtimeType.toString()),
      );
      final tracker = BusyTracker(bus: bus);
      expect(
        await tracker.track(
          activity: BusyActivity.findingMeetings,
          work: () async => 42,
        ),
        42,
      );
      await expectLater(
        tracker.track<int>(
          activity: BusyActivity.findingMeetings,
          work: () async => throw StateError('offline'),
        ),
        throwsStateError,
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, ['BusyStarted', 'BusyEnded', 'BusyStarted', 'BusyEnded']);
      await subscription.cancel();
      await bus.dispose();
    });
  });
}
