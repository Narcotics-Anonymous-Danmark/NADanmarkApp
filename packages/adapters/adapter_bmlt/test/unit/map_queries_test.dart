@Tags(['unit'])
library;

import 'package:adapter_bmlt/adapter_bmlt.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const tomato = 'https://tomato.example/json/';

const endpoints = BmltEndpoints(
  denmark: BmltBaseUrl('https://denmark.example/json/'),
  tomato: BmltBaseUrl(tomato),
);

({BmltServerMimic mimic, DioMeetingSearch search}) adapter() {
  final mimic = BmltServerMimic();
  return (
    mimic: mimic,
    search: DioMeetingSearch(
      dio: Dio()..httpClientAdapter = mimic,
      endpoints: endpoints,
    ),
  );
}

void main() {
  group('Requirement: Auto radius', () {
    test('Pins query carries the exact parameters', () async {
      final subject = adapter();
      await subject.search.meetingSpots(
        centre: GeoPoint.searchFallback,
        radius: const MapRadius(21.99999999),
      );
      expect(
        subject.mimic.requests.single.toString(),
        '$tomato?switcher=GetSearchResults'
        '&data_field_key=longitude,latitude,id_bigint&geo_width_km=22'
        '&long_val=8.4606976&lat_val=55.476224'
        '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
      );
    });

    test('the recorded rows decode to spots', () async {
      final outcome = await adapter().search.meetingSpots(
        centre: aGeoPoint(),
        radius: const MapRadius(5),
      );
      final spots = (outcome as Ok<List<MeetingSpot>, Failure>).value;
      expect(spots, hasLength(12));
      expect(spots.first.id, const MeetingId(43394));
    });

    test('an empty object is no spots', () async {
      final subject = adapter();
      subject.mimic.serve(
        endpoint: BmltEndpoint.spots,
        reply: const BmltNoResults(),
      );
      final outcome = await subject.search.meetingSpots(
        centre: aGeoPoint(),
        radius: const MapRadius(5),
      );
      expect((outcome as Ok<List<MeetingSpot>, Failure>).value, isEmpty);
    });

    test('failures keep their kind', () async {
      final subject = adapter();
      subject.mimic.serve(
        endpoint: BmltEndpoint.spots,
        reply: const BmltUnreachable(),
      );
      final unreachable = await subject.search.meetingSpots(
        centre: aGeoPoint(),
        radius: const MapRadius(5),
      );
      expect(
        (unreachable as Err<List<MeetingSpot>, Failure>).error,
        isA<NetworkFailure>(),
      );
      subject.mimic.serve(
        endpoint: BmltEndpoint.spots,
        reply: const BmltMalformed(),
      );
      final malformed = await subject.search.meetingSpots(
        centre: aGeoPoint(),
        radius: const MapRadius(5),
      );
      expect(
        (malformed as Err<List<MeetingSpot>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });
  });

  group('Requirement: Meeting details modal', () {
    test('By-id query carries every id', () async {
      final subject = adapter();
      await subject.search.meetingsById(
        ids: const [MeetingId(123), MeetingId(456)],
      );
      final request = subject.mimic.requests.single;
      expect(request.queryParametersAll['meeting_ids[]'], ['123', '456']);
      expect(request.queryParameters['switcher'], 'GetSearchResults');
    });

    test('the meetings come back in the server order', () async {
      final subject = adapter();
      subject.mimic.serve(
        endpoint: BmltEndpoint.byId,
        reply: BmltRows.meetings(
          meetings: [aBmltMeetingDto(id: 456), aBmltMeetingDto(id: 123)],
        ),
      );
      final outcome = await subject.search.meetingsById(
        ids: const [MeetingId(123), MeetingId(456)],
      );
      expect(
        (outcome as Ok<List<Meeting>, Failure>).value.map((m) => m.id),
        const [MeetingId(456), MeetingId(123)],
      );
    });

    test('the default reply only holds the requested meetings', () async {
      final outcome = await adapter().search.meetingsById(
        ids: const [MeetingId(115)],
      );
      expect(
        (outcome as Ok<List<Meeting>, Failure>).value.map((m) => m.id),
        const [MeetingId(115)],
      );
    });

    test('an unreachable server is a network failure', () async {
      final subject = adapter();
      subject.mimic.serve(
        endpoint: BmltEndpoint.byId,
        reply: const BmltUnreachable(),
      );
      final outcome = await subject.search.meetingsById(
        ids: const [MeetingId(1)],
      );
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<NetworkFailure>(),
      );
    });
  });
}
