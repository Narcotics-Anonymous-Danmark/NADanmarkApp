@Tags(['unit'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

const tomato = 'https://tomato.example/json/';

Uri nearbyQuery({required Km radius}) => Uri.parse(
  '$tomato?switcher=GetSearchResults&geo_width_km=${radius.value}'
  '&long_val=8.4606976&lat_val=55.476224'
  '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
);

GeolocationMimic geolocationAt({
  required TestTime time,
  LocationAccess access = LocationAccess.granted,
  PromptAnswer answer = PromptAnswer.grant,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
}) => GeolocationMimic(
  time: time,
  currentAccess: access,
  promptAnswer: answer,
  delivery: delivery,
);

TestTime aTestTime() => TestTime.copenhagen(startAt: anInstant());

RowCount rowCount({required Response<String> response}) =>
    switch (jsonDecode(response.data ?? '')) {
      final List<Object?> rows => RowCount(rows.length),
      final Object? other => fail('not a list: $other'),
    };

void main() {
  group('GeolocationMimic', () {
    test('reports access and counts every call', () async {
      final mimic = geolocationAt(
        time: aTestTime(),
        access: LocationAccess.askable,
      );
      expect(await mimic.access(), LocationAccess.askable);
      expect(await mimic.currentPosition(), const NoFix());
      expect(mimic.accessCalls, const CallCount(1));
      expect(mimic.positionCalls, const CallCount(1));
      expect(mimic.calls, const CallCount(2));
    });

    test('a granted prompt grants access from then on', () async {
      final mimic = geolocationAt(
        time: aTestTime(),
        access: LocationAccess.askable,
      );
      expect(await mimic.requestAccess(), LocationAccess.granted);
      expect(await mimic.access(), LocationAccess.granted);
      expect(mimic.requestCalls, const CallCount(1));
    });

    test('a refused prompt refuses access from then on', () async {
      final mimic = geolocationAt(
        time: aTestTime(),
        access: LocationAccess.askable,
        answer: PromptAnswer.refuse,
      );
      expect(await mimic.requestAccess(), LocationAccess.refused);
      expect(await mimic.access(), LocationAccess.refused);
    });

    test('an ignored prompt never answers', () async {
      final mimic = geolocationAt(
        time: aTestTime(),
        access: LocationAccess.askable,
        answer: PromptAnswer.ignore,
      );
      var answered = 0;
      unawaited(mimic.requestAccess().then((_) => answered += 1));
      await Future<void>.delayed(Duration.zero);
      expect(answered, 0);
    });

    test('a delayed fix arrives when the test time reaches it', () async {
      final time = aTestTime();
      final point = aGeoPoint(
        latitude: const Latitude(56.15),
        longitude: const Longitude(10.2),
      );
      final mimic = geolocationAt(
        time: time,
        delivery: FixAfter(
          delay: const Duration(seconds: 12),
          fix: Located(point: point),
        ),
      );
      final fixes = <PositionFix>[];
      unawaited(mimic.currentPosition().then(fixes.add));
      time.advance(by: const Duration(seconds: 11));
      await Future<void>.delayed(Duration.zero);
      expect(fixes, isEmpty);
      time.advance(by: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(fixes, [Located(point: point)]);
    });

    test('a fix that never comes leaves the call pending', () async {
      final mimic = geolocationAt(
        time: aTestTime(),
        delivery: const FixNever(),
      );
      var answered = 0;
      unawaited(mimic.currentPosition().then((_) => answered += 1));
      await Future<void>.delayed(Duration.zero);
      expect(answered, 0);
    });

    test('the test container binds a granted mimic with a fix', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      expect(harness.read(geolocationPortProvider), same(harness.geolocation));
      expect(await harness.geolocation.access(), LocationAccess.granted);
      expect(
        await harness.geolocation.currentPosition(),
        Located(point: aGeoPoint()),
      );
    });
  });

  group('MeetingSearchMimic nearby', () {
    test('serves meetings per radius and records each query', () async {
      final mimic = MeetingSearchMimic.recorded()
        ..serveNearby(
          radius: const Km(30),
          result: const Ok(value: []),
        );
      final centre = aGeoPoint();
      final standard = await mimic.nearbyMeetings(
        centre: centre,
        radius: const Km(15),
      );
      final wide = await mimic.nearbyMeetings(
        centre: centre,
        radius: const Km(30),
      );
      expect((standard as Ok<List<Meeting>, Failure>).value, hasLength(3));
      expect((wide as Ok<List<Meeting>, Failure>).value, isEmpty);
      expect(mimic.nearbyQueries, [
        NearbyQuery(centre: centre, radius: const Km(15)),
        NearbyQuery(centre: centre, radius: const Km(30)),
      ]);
      expect(mimic.nearbyQueries.first.toString(), contains('15 km'));
      expect(
        mimic.nearbyQueries.first.hashCode,
        NearbyQuery(centre: centre, radius: const Km(15)).hashCode,
      );
    });

    test('a held nearby search answers only after its gate opens', () async {
      final mimic = MeetingSearchMimic.recorded();
      final gate = mimic.holdNearby();
      var answered = 0;
      final pending = mimic
          .nearbyMeetings(centre: aGeoPoint(), radius: const Km(15))
          .then((_) => answered += 1);
      await Future<void>.delayed(Duration.zero);
      expect(answered, 0);
      gate.open();
      await pending;
      expect(answered, 1);
    });
  });

  group('BmltServerMimic nearby', () {
    test('routes radius queries apart from the full Denmark list', () async {
      final mimic = BmltServerMimic()
        ..serve(endpoint: BmltEndpoint.nearby, reply: aNearbyBmltResponse());
      final dio = Dio()..httpClientAdapter = mimic;
      final response = await dio.getUri<String>(
        nearbyQuery(radius: const Km(15)),
      );
      expect(rowCount(response: response), const RowCount(3));
      expect(
        mimic.requestsTo(endpoint: BmltEndpoint.nearby).single,
        nearbyQuery(radius: const Km(15)),
      );
      expect(mimic.requestsTo(endpoint: BmltEndpoint.meetings), isEmpty);
    });

    test('serves different rows per radius, released out of order', () async {
      final mimic = BmltServerMimic()
        ..serveNearby(
          radius: const Km(15),
          reply: aNearbyBmltResponse(count: const RowCount(1)),
        )
        ..serveNearby(
          radius: const Km(30),
          reply: aNearbyBmltResponse(count: const RowCount(2)),
        );
      final narrow = mimic.holdNearby(radius: const Km(15));
      final wide = mimic.holdNearby(radius: const Km(30));
      final dio = Dio()..httpClientAdapter = mimic;
      final order = <RowCount>[];
      final first = dio
          .getUri<String>(nearbyQuery(radius: const Km(15)))
          .then((response) => order.add(rowCount(response: response)));
      final second = dio
          .getUri<String>(nearbyQuery(radius: const Km(30)))
          .then((response) => order.add(rowCount(response: response)));
      await Future<void>.delayed(Duration.zero);
      wide.release();
      await second;
      narrow.release();
      await first;
      expect(order, const [RowCount(2), RowCount(1)]);
    });

    test('an unknown radius falls back to the nearby reply', () async {
      final mimic = BmltServerMimic()
        ..serve(endpoint: BmltEndpoint.nearby, reply: const BmltNoResults());
      final response = await (Dio()..httpClientAdapter = mimic).getUri<String>(
        nearbyQuery(radius: const Km(42)),
      );
      expect(response.data, '{}');
    });
  });
}
