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

({BmltServerMimic mimic, DioMeetingSearch search}) nearbyAdapter({
  BmltReply reply = const BmltNoResults(),
}) {
  final mimic = BmltServerMimic()
    ..serve(endpoint: BmltEndpoint.nearby, reply: reply);
  return (
    mimic: mimic,
    search: DioMeetingSearch(
      dio: Dio()..httpClientAdapter = mimic,
      endpoints: endpoints,
    ),
  );
}

Future<Outcome<List<Meeting>, Failure>> searchAround({
  required DioMeetingSearch search,
  GeoPoint centre = GeoPoint.searchFallback,
  Km radius = const Km(15),
}) => search.nearbyMeetings(centre: centre, radius: radius);

void main() {
  group('Requirement: BMLT endpoints', () {
    test('Radius query carries the exact parameters', () async {
      final subject = nearbyAdapter(reply: aNearbyBmltResponse());
      final outcome = await searchAround(search: subject.search);
      expect((outcome as Ok<List<Meeting>, Failure>).value, hasLength(3));
      expect(
        subject.mimic.requests.single.toString(),
        '$tomato?switcher=GetSearchResults&geo_width_km=15'
        '&long_val=8.4606976&lat_val=55.476224'
        '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
      );
    });

    test('coordinates keep their shortest decimal form', () async {
      final subject = nearbyAdapter();
      await searchAround(
        search: subject.search,
        centre: aGeoPoint(
          latitude: const Latitude(56.15),
          longitude: const Longitude(10.2),
        ),
        radius: const Km(30),
      );
      expect(
        subject.mimic.requests.single.toString(),
        '$tomato?switcher=GetSearchResults&geo_width_km=30'
        '&long_val=10.2&lat_val=56.15'
        '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
      );
    });

    test('Empty object means no meetings', () async {
      final outcome = await searchAround(search: nearbyAdapter().search);
      expect((outcome as Ok<List<Meeting>, Failure>).value, isEmpty);
    });
  });

  group('Failures', () {
    test('an unreachable server is a network failure', () async {
      final outcome = await searchAround(
        search: nearbyAdapter(reply: const BmltUnreachable()).search,
      );
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<NetworkFailure>(),
      );
    });

    test('a body that is not JSON is a decode failure', () async {
      final outcome = await searchAround(
        search: nearbyAdapter(reply: const BmltMalformed()).search,
      );
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });

    test('JSON of the wrong shape is a decode failure', () async {
      final outcome = await searchAround(
        search: nearbyAdapter(
          reply: const BmltServerError(statusCode: 200),
        ).search,
      );
      expect(
        (outcome as Err<List<Meeting>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });
  });
}
