@Tags(['unit'])
library;

import 'package:adapter_bmlt/adapter_bmlt.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/riverpod.dart';

const endpoints = BmltEndpoints(
  denmark: BmltBaseUrl('https://denmark.example/json/'),
  tomato: BmltBaseUrl('https://tomato.example/json/'),
);

({BmltServerMimic mimic, DioMeetingSearch search, DioMeetingFormats formats})
adapters() {
  final mimic = BmltServerMimic();
  final dio = Dio()..httpClientAdapter = mimic;
  return (
    mimic: mimic,
    search: DioMeetingSearch(dio: dio, endpoints: endpoints),
    formats: DioMeetingFormats(dio: dio, endpoints: endpoints),
  );
}

void main() {
  group('Requirement: BMLT endpoints', () {
    test('all meetings use the exact Denmark query', () async {
      final subject = adapters();
      final outcome = await subject.search.denmarkMeetings();
      expect((outcome as Ok<List<Meeting>, Failure>).value, hasLength(3));
      expect(
        subject.mimic.requests.single.toString(),
        'https://denmark.example/json/?switcher=GetSearchResults'
        '&sort_keys=weekday_tinyint,start_time',
      );
    });

    test('municipalities use the exact Denmark query', () async {
      final subject = adapters();
      final outcome = await subject.search.denmarkMunicipalities();
      expect(
        (outcome as Ok<List<MunicipalityName>, Failure>).value,
        hasLength(168),
      );
      expect(
        subject.mimic.requests.single.toString(),
        'https://denmark.example/json/?switcher=GetSearchResults'
        '&data_field_key=location_municipality'
        '&sort_keys=location_municipality',
      );
    });

    test('formats are fetched in both languages and concatenated', () async {
      final subject = adapters();
      final outcome = await subject.formats.formatRows();
      final rows = (outcome as Ok<List<FormatRow>, Failure>).value;
      expect(rows, hasLength(54));
      expect(rows.first.language, FormatLanguageCode.danish);
      expect(rows.last.language, FormatLanguageCode.english);
      expect(subject.mimic.requests.map((uri) => uri.toString()), [
        'https://denmark.example/json/?switcher=GetFormats&lang_enum=da',
        'https://denmark.example/json/?switcher=GetFormats&lang_enum=en',
      ]);
    });

    test('an empty object means no meetings and no formats', () async {
      final subject = adapters();
      for (final endpoint in BmltEndpoint.values) {
        subject.mimic.serve(endpoint: endpoint, reply: const BmltNoResults());
      }
      expect(
        (await subject.search.denmarkMeetings() as Ok<List<Meeting>, Failure>)
            .value,
        isEmpty,
      );
      expect(
        (await subject.formats.formatRows() as Ok<List<FormatRow>, Failure>)
            .value,
        isEmpty,
      );
    });
  });

  group('Failures', () {
    test('an unreachable server is a network failure', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.municipalities,
        reply: const BmltUnreachable(),
      );
      final outcome = await subject.search.denmarkMunicipalities();
      expect(
        (outcome as Err<List<MunicipalityName>, Failure>).error,
        isA<NetworkFailure>(),
      );
    });

    test('a server error is a network failure', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.meetings,
        reply: const BmltServerError(statusCode: 503),
      );
      final outcome = await subject.search.denmarkMeetings();
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        const NetworkFailure(
          detail:
              'https://denmark.example/json/?switcher=GetSearchResults'
              '&sort_keys=weekday_tinyint,start_time: badResponse',
        ),
      );
    });

    test('a body that is not JSON is a decode failure', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.meetings,
        reply: const BmltMalformed(),
      );
      final outcome = await subject.search.denmarkMeetings();
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });

    test('JSON of the wrong shape is a decode failure', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.meetings,
        reply: const BmltServerError(statusCode: 200),
      );
      final outcome = await subject.search.denmarkMeetings();
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });

    test('one failing language fails the formats fetch', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.formatsEnglish,
        reply: const BmltUnreachable(),
      );
      final outcome = await subject.formats.formatRows();
      expect(
        (outcome as Err<List<FormatRow>, Failure>).error,
        isA<NetworkFailure>(),
      );
    });

    test('a malformed formats body is a decode failure', () async {
      final subject = adapters();
      subject.mimic.serve(
        endpoint: BmltEndpoint.formatsDanish,
        reply: const BmltServerError(statusCode: 200),
      );
      final outcome = await subject.formats.formatRows();
      expect(
        (outcome as Err<List<FormatRow>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });
  });

  test('bmltOverrides binds both ports', () {
    final container = ProviderContainer(
      overrides: bmltOverrides(dio: Dio(), endpoints: endpoints),
    );
    addTearDown(container.dispose);
    expect(container.read(meetingSearchPortProvider), isA<DioMeetingSearch>());
    expect(
      container.read(meetingFormatsPortProvider),
      isA<DioMeetingFormats>(),
    );
  });
}
