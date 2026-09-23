@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

const reader = BmltMeetingReader();
const codec = FormatRowsCodec();
const legacy = LegacyMeetingFormatsTranslator();

List<Meeting> recordedMeetings() =>
    switch (reader.meetings(json: bmltFixture(name: 'denmark_meetings.json'))) {
      Ok(:final value) => value,
      Err(:final error) => fail('$error'),
    };

void main() {
  group('BMLT meeting rows', () {
    test('a recorded in-person meeting decodes every field', () {
      final meeting = recordedMeetings().first;
      expect(meeting.id, const MeetingId(115));
      expect(meeting.name, 'Traditionerne tro');
      expect(meeting.weekday, Weekday.sunday);
      expect(meeting.times.toString(), '11:00 - 12:00');
      expect(meeting.formatCodes.keys, hasLength(6));
      expect(meeting.formatCodes.sharedIds.first, const FormatId(4));
      expect(meeting.origin, MeetingOrigin.denmark);
      expect(
        meeting.location,
        const Mapped(
          point: GeoPoint(latitude: 55.6201832, longitude: 8.4830404),
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
          lines: 'Dørene åbnes KL.16:00',
        ),
      ]);
    });

    test('values are trimmed and blank values are absent', () {
      final outcome = reader.meeting(
        reader: const JsonReader(
          json: {
            'id_bigint': '7',
            'weekday_tinyint': '2',
            'start_time': '19:00:00',
            'duration_time': '',
            'meeting_name': '  Møde  ',
            'location_street': '  ',
            'location_postal_code_1': ' 8000 ',
            'comments': ' Husk ',
            'phone_meeting_number': ' ',
            'root_server_uri': 'https://tomato.example',
            'root_server_id': '',
            'latitude': '0',
            'longitude': '0',
          },
          context: 'row',
        ),
      );
      final meeting = (outcome as Ok<Meeting, DecodeFailure>).value;
      expect(meeting.name, 'Møde');
      expect(meeting.locationLines, [const LocationLine('8000')]);
      expect(meeting.comment, const Comment(text: 'Husk'));
      expect(meeting.dialIn, const NoDialIn());
      expect(meeting.duration, Duration.zero);
      expect(meeting.origin, MeetingOrigin.otherRoot);
      expect(meeting.location, const Unmapped());
      expect(meeting.municipality, const OnlineMunicipality());
    });

    test('a root server id marks an aggregated Danish meeting', () {
      final outcome = reader.meeting(
        reader: const JsonReader(
          json: {
            'id_bigint': 8,
            'weekday_tinyint': 1,
            'start_time': '10:00',
            'root_server_uri': 'https://www.nadanmark.dk/main_server',
            'root_server_id': '12',
            'phone_meeting_number': '+45 1',
          },
          context: 'row',
        ),
      );
      final meeting = (outcome as Ok<Meeting, DecodeFailure>).value;
      expect(meeting.origin, MeetingOrigin.denmarkAggregated);
      expect(meeting.dialIn, const DialInNumber(number: '+45 1'));
    });

    test('an empty object is no meetings and malformed rows are skipped', () {
      expect(
        (reader.meetings(json: <String, Object?>{})
                as Ok<List<Meeting>, DecodeFailure>)
            .value,
        isEmpty,
      );
      final outcome = reader.meetings(
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
        reader.meetings(json: 'oops'),
        isA<Err<List<Meeting>, DecodeFailure>>(),
      );
      expect(
        reader.meetings(json: {'error': 'x'}),
        isA<Err<List<Meeting>, DecodeFailure>>(),
      );
    });

    test('the recorded municipality rows decode in server order', () {
      final outcome = reader.municipalities(
        json: bmltFixture(name: 'denmark_municipalities.json'),
      );
      final names =
          (outcome as Ok<List<MunicipalityName>, DecodeFailure>).value;
      expect(names, hasLength(168));
      expect(names.first, const MunicipalityName('2300 københavn s'));
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
      expect(rows.first.raw.text, contains('root_server_uri'));
    });

    test('rows without an id are skipped and {} is empty', () {
      expect(
        (codec.rows(
                  json: [
                    {'key_string': 'A'},
                    {'id': '1', 'key_string': 'B'},
                  ],
                )
                as Ok<List<FormatRow>, DecodeFailure>)
            .value
            .single
            .key,
        const FormatKey('B'),
      );
      expect(
        (codec.rows(json: <String, Object?>{})
                as Ok<List<FormatRow>, DecodeFailure>)
            .value,
        isEmpty,
      );
      expect(codec.rows(json: 3), isA<Err<List<FormatRow>, DecodeFailure>>());
    });

    test('a snapshot survives an encode and decode round trip unchanged', () {
      final snapshot = FormatsSnapshot(
        fetchedAt: Instant(DateTime.utc(2026, 9, 10, 12)),
        rows: recordedFormatRows(),
      );
      final text = codec.encodeSnapshot(snapshot: snapshot);
      expect(
        codec.decodeSnapshot(text: text),
        Ok<FormatsSnapshot, DecodeFailure>(value: snapshot),
      );
      expect(text, startsWith('{"fetchedAt":1789041600000,"formats":[{'));
    });

    test('a malformed cache is a decode failure', () {
      for (final text in ['nope', '[]', '{"fetchedAt":"x","formats":[]}']) {
        expect(
          codec.decodeSnapshot(text: text),
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
      expect(snapshot.toString(), contains('0 rows'));
    });
  });

  group('Legacy meeting formats cache', () {
    const row = {'id': '17', 'key_string': 'ÅM', 'lang': 'da'};

    test('a cache with rows is re-encoded unchanged', () {
      expect(
        legacy.translate(
          value: {
            'fetchedAt': 1757500000000,
            'formats': [row],
          },
        ),
        const ImportFormatsCache(
          encoded:
              '{"fetchedAt":1757500000000,"formats":'
              '[{"id":"17","key_string":"ÅM","lang":"da"}]}',
        ),
      );
    });

    test('a cache stored as a JSON string is read too', () {
      expect(
        legacy.translate(value: '{"fetchedAt":1,"formats":[{"id":"1"}]}'),
        isA<ImportFormatsCache>(),
      );
    });

    test('an empty, malformed or missing cache is skipped', () {
      for (final value in <Object?>[
        {'fetchedAt': 1757500000000, 'formats': <Object?>[]},
        {
          'formats': [row],
        },
        {
          'fetchedAt': 'x',
          'formats': [row],
        },
        'nope',
        '"text"',
        null,
        42,
      ]) {
        expect(
          legacy.translate(value: value),
          const SkipFormatsCache(),
          reason: '$value',
        );
      }
    });
  });

  group('Busy events', () {
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
  });
}
