@Tags(['unit'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:na_testing/src/generated/recorded_bmlt.dart';

const denmark = 'https://denmark.example/json/';
const allMeetings =
    '$denmark?switcher=GetSearchResults&sort_keys=weekday_tinyint,start_time';
const municipalityQuery =
    '$denmark?switcher=GetSearchResults'
    '&data_field_key=location_municipality';

Object? fixture({required String name}) => jsonDecode(
  File(
    '${RepoAssetBundle.locate().repoRoot.path}'
    '/packages/core/na_testing/fixtures/wire/bmlt/$name',
  ).readAsStringSync(),
);

Dio dioFor({required BmltServerMimic mimic}) =>
    Dio()..httpClientAdapter = mimic;

void main() {
  group('Recorded BMLT fixtures', () {
    test('the generated mirror matches the recorded JSON files', () {
      expect(recordedDenmarkMeetings, fixture(name: 'denmark_meetings.json'));
      final municipalities = switch (fixture(
        name: 'denmark_municipalities.json',
      )) {
        final List<Object?> rows => rows.map(
          (row) => switch (row) {
            {'location_municipality': final String name} => name,
            _ => fail('not a municipality row: $row'),
          },
        ),
        final Object? other => fail('not a list: $other'),
      };
      expect(recordedDenmarkMunicipalities, municipalities);
      expect(recordedFormatsDa, fixture(name: 'formats_da.json'));
      expect(recordedFormatsEn, fixture(name: 'formats_en.json'));
    });
  });

  group('Builders', () {
    test('aMeeting decodes the recorded row through the boundary reader', () {
      final meeting = aMeeting();
      expect(meeting.id, const MeetingId(115));
      expect(meeting.weekday, Weekday.sunday);
      expect(meeting.municipality.toString(), 'Varde');
      expect(meeting.formatCodes.keys, hasLength(6));
      expect(meeting.locationLines.map((line) => line.text), [
        'Frivillighuset',
        'Storegade 25B',
        'Varde',
        '6800 Varde',
      ]);
      expect(
        meeting.comment,
        const Comment(text: 'Dyr er ikke tilladt i lokalerne'),
      );
    });

    test('builder overrides reach the domain value', () {
      final meeting = aMeeting(
        id: 7,
        weekday: Weekday.friday,
        startTime: '18:30:00',
        virtualLink: 'https://zoom.example/j/9',
        phoneMeeting: '+45 1',
        busLines: 'Bus Lines#@-@#5C',
      );
      expect(meeting.id, const MeetingId(7));
      expect(meeting.weekday, Weekday.friday);
      expect(
        meeting.start,
        const LocalTime(hour: HourOfDay(18), minute: MinuteOfHour(30)),
      );
      expect(meeting.actions, hasLength(2));
      expect(meeting.transitLines.single.lines, '5C');
    });

    test('a malformed builder row fails loudly', () {
      expect(() => aMeeting(startTime: 'x'), throwsArgumentError);
    });

    test('format builders decode through the codec', () {
      expect(aMeetingFormatRow().key, const FormatKey('ÅM'));
      expect(
        aMeetingFormatRow(language: 'en').language,
        FormatLanguageCode.english,
      );
      expect(recordedFormatRows(), hasLength(54));
      expect(aBmltFormatJson(id: 1)['id'], '1');
      expect(aBmltMunicipalityJson(), {'location_municipality': 'Varde'});
    });
  });

  group('BmltServerMimic', () {
    test('serves the recorded rows per query and records every URI', () async {
      final mimic = BmltServerMimic();
      final dio = dioFor(mimic: mimic);
      final meetings = await dio.get<String>(allMeetings);
      final municipalities = await dio.get<String>(municipalityQuery);
      final danish = await dio.get<String>(
        '$denmark?switcher=GetFormats&lang_enum=da',
      );
      final english = await dio.get<String>(
        '$denmark?switcher=GetFormats&lang_enum=en',
      );
      expect(jsonDecode(meetings.data ?? ''), hasLength(3));
      expect(jsonDecode(municipalities.data ?? ''), hasLength(168));
      expect(jsonDecode(danish.data ?? ''), hasLength(29));
      expect(jsonDecode(english.data ?? ''), hasLength(25));
      expect(mimic.requests, hasLength(4));
      expect(
        mimic
            .requestsTo(endpoint: BmltEndpoint.formatsEnglish)
            .single
            .toString(),
        '$denmark?switcher=GetFormats&lang_enum=en',
      );
    });

    test('answers {} for no results and 404 for an unknown query', () async {
      final mimic = BmltServerMimic()
        ..serve(endpoint: BmltEndpoint.meetings, reply: const BmltNoResults());
      final dio = dioFor(mimic: mimic);
      final empty = await dio.get<String>('$denmark?switcher=GetSearchResults');
      expect(empty.data, '{}');
      await expectLater(
        dio.get<String>('$denmark?switcher=GetServiceBodies'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            404,
          ),
        ),
      );
    });

    test(
      'fails as a server error, as unreachable or with a malformed body',
      () async {
        final mimic = BmltServerMimic()
          ..serve(
            endpoint: BmltEndpoint.meetings,
            reply: const BmltServerError(statusCode: 503),
          )
          ..serve(
            endpoint: BmltEndpoint.municipalities,
            reply: const BmltUnreachable(),
          )
          ..serve(
            endpoint: BmltEndpoint.formatsDanish,
            reply: const BmltMalformed(),
          );
        final dio = dioFor(mimic: mimic);
        await expectLater(
          dio.get<String>('$denmark?switcher=GetSearchResults'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.badResponse,
            ),
          ),
        );
        await expectLater(
          dio.get<String>(municipalityQuery),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.connectionError,
            ),
          ),
        );
        final malformed = await dio.get<String>(
          '$denmark?switcher=GetFormats&lang_enum=da',
        );
        expect(malformed.data, '<html>');
      },
    );

    test('a held endpoint answers only after release', () async {
      final mimic = BmltServerMimic();
      final held = mimic.hold(endpoint: BmltEndpoint.meetings);
      var answered = 0;
      final pending = dioFor(mimic: mimic)
          .get<String>('$denmark?switcher=GetSearchResults')
          .then((response) => answered += 1);
      await Future<void>.delayed(Duration.zero);
      expect(answered, 0);
      held.release();
      await pending;
      expect(answered, 1);
    });
  });

  group('Port mimics', () {
    test(
      'the search mimic serves recorded data, counts calls and can hold',
      () async {
        final mimic = MeetingSearchMimic.recorded();
        expect(
          (await mimic.denmarkMeetings() as Ok<List<Meeting>, Failure>).value,
          hasLength(3),
        );
        expect(
          (await mimic.denmarkMunicipalities()
                  as Ok<List<MunicipalityName>, Failure>)
              .value,
          hasLength(168),
        );
        final gate = mimic.holdMeetings();
        var done = 0;
        final pending = mimic.denmarkMeetings().then((_) => done += 1);
        await Future<void>.delayed(Duration.zero);
        expect(done, 0);
        gate.open();
        await pending;
        expect(mimic.meetingCalls, 2);
        expect(mimic.municipalityCalls, 1);
        final municipalityGate = mimic.holdMunicipalities();
        final held = mimic.denmarkMunicipalities();
        municipalityGate.open();
        await held;
      },
    );

    test('the formats mimic serves the recorded rows and can hold', () async {
      final mimic = MeetingFormatsMimic.recorded();
      final gate = mimic.hold();
      final pending = mimic.formatRows();
      gate.open();
      expect(
        (await pending as Ok<List<FormatRow>, Failure>).value,
        hasLength(54),
      );
      expect(mimic.calls, 1);
    });

    test('the test container binds both port mimics', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      expect(
        harness.read(meetingSearchPortProvider),
        same(harness.meetingSearch),
      );
      expect(
        harness.read(meetingFormatsPortProvider),
        same(harness.meetingFormats),
      );
    });
  });
}
