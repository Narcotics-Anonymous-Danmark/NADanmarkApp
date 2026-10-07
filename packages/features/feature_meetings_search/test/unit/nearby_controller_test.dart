@Tags(['unit'])
library;

import 'dart:async';

import 'package:feature_meetings_search/feature_meetings_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

final GeoPoint aarhus = aGeoPoint(
  latitude: const Latitude(56.15),
  longitude: const Longitude(10.2),
);

final Meeting monday = aMeeting(id: 1, weekday: Weekday.monday);
final Meeting friday = aMeeting(id: 2, weekday: Weekday.friday);

TestContainer nearbyHarness({
  Map<String, String> storedValues = const {},
  LocationAccess access = LocationAccess.granted,
  PromptAnswer answer = PromptAnswer.grant,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
}) {
  final harness = TestContainer.build(storedValues: storedValues);
  addTearDown(harness.dispose);
  harness.geolocation
    ..currentAccess = access
    ..promptAnswer = answer
    ..delivery = delivery;
  harness.meetingSearch.nearby = Ok(value: [monday]);
  return harness;
}

Future<void> flush() async {
  for (var turn = 0; turn < 10; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<NearbyMeetingsController> open(TestContainer harness) async {
  final subscription = harness.container.listen(
    nearbyMeetingsProvider,
    (previous, next) {},
  );
  addTearDown(subscription.close);
  await flush();
  return harness.read(nearbyMeetingsProvider.notifier);
}

Future<void> advance(TestContainer harness, Duration by) async {
  harness.time.advance(by: by);
  await flush();
}

NearbyState stateOf(TestContainer harness) =>
    harness.read(nearbyMeetingsProvider);

List<NearbyQuery> queries(TestContainer harness) =>
    List.unmodifiable(harness.meetingSearch.nearbyQueries);

NearbyQuery query({required GeoPoint at, Km radius = const Km(15)}) =>
    NearbyQuery(centre: at, radius: radius);

FixDelivery locatedAt(GeoPoint point) => FixAtOnce(fix: Located(point: point));

List<BusyActivity> started(TestContainer harness) => List.unmodifiable(
  harness.events.recordedOf<BusyStarted>().map((event) => event.activity),
);

List<BusyActivity> ended(TestContainer harness) => List.unmodifiable(
  harness.events.recordedOf<BusyEnded>().map((event) => event.activity),
);

void main() {
  group('radius', () {
    test('starts from the stored search range', () async {
      final harness = nearbyHarness(
        storedValues: {'searchRange': '20'},
        delivery: locatedAt(aarhus),
      );
      await open(harness);
      expect(stateOf(harness).radius, const Km(20));
      expect(queries(harness), [query(at: aarhus, radius: const Km(20))]);
    });

    test('a slider change searches 500 ms after the last change', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      final controller = await open(harness);
      controller.changeRadius(radius: const Km(25));
      await advance(harness, const Duration(milliseconds: 300));
      controller.changeRadius(radius: const Km(30));
      expect(stateOf(harness).radius, const Km(30));
      await advance(harness, const Duration(milliseconds: 499));
      expect(queries(harness), hasLength(1));
      await advance(harness, const Duration(milliseconds: 1));
      expect(queries(harness), [
        query(at: aarhus),
        query(at: aarhus, radius: const Km(30)),
      ]);
      expect(harness.geolocation.positionCalls, const CallCount(1));
    });

    test('a slider change never writes the setting', () async {
      final harness = nearbyHarness(
        storedValues: {'searchRange': '15'},
        delivery: locatedAt(aarhus),
      );
      final controller = await open(harness);
      controller.changeRadius(radius: const Km(40));
      await advance(harness, NearbyMeetingsController.sliderDebounce);
      expect(harness.storage.snapshot, {'searchRange': '15'});
      expect(harness.storage.writes, isEmpty);
    });

    test('a new page visit starts again from the stored radius', () async {
      final harness = nearbyHarness(
        storedValues: {'searchRange': '15'},
        delivery: locatedAt(aarhus),
      );
      final subscription = harness.container.listen(
        nearbyMeetingsProvider,
        (previous, next) {},
      );
      await flush();
      harness
          .read(nearbyMeetingsProvider.notifier)
          .changeRadius(
            radius: const Km(40),
          );
      subscription.close();
      await flush();
      await open(harness);
      expect(stateOf(harness).radius, const Km(15));
    });
  });

  group('locating', () {
    test('a fix searches around the device position', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      await open(harness);
      expect(queries(harness), [query(at: aarhus)]);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [monday],
          origin: DevicePosition(point: aarhus),
        ),
      );
      expect(started(harness), [
        BusyActivity.locating,
        BusyActivity.findingMeetings,
      ]);
      expect(ended(harness), [
        BusyActivity.locating,
        BusyActivity.findingMeetings,
      ]);
    });

    test('with permission the search waits 10 s for a fix', () async {
      final harness = nearbyHarness(delivery: const FixNever());
      await open(harness);
      await advance(harness, const Duration(seconds: 9));
      expect(queries(harness), isEmpty);
      expect(ended(harness), isEmpty);
      await advance(harness, const Duration(seconds: 1));
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
      expect(
        stateOf(harness).results,
        Shown(meetings: [monday], origin: const DefaultPosition()),
      );
      expect(ended(harness).first, BusyActivity.locating);
    });

    test('a fix after the timeout searches again', () async {
      final harness = nearbyHarness(
        delivery: FixAfter(
          delay: const Duration(seconds: 22),
          fix: Located(point: aarhus),
        ),
      );
      await open(harness);
      await advance(harness, const Duration(seconds: 10));
      harness.meetingSearch.nearby = Ok(value: [friday]);
      await advance(harness, const Duration(seconds: 12));
      expect(queries(harness), [
        query(at: GeoPoint.searchFallback),
        query(at: aarhus),
      ]);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [friday],
          origin: DevicePosition(point: aarhus),
        ),
      );
    });

    test('without permission the prompt gets 45 s', () async {
      final harness = nearbyHarness(
        access: LocationAccess.askable,
        answer: PromptAnswer.ignore,
        delivery: const FixNever(),
      );
      await open(harness);
      expect(harness.geolocation.requestCalls, const CallCount(1));
      await advance(harness, const Duration(seconds: 44));
      expect(queries(harness), isEmpty);
      await advance(harness, const Duration(seconds: 1));
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
    });

    test('a refused permission searches at once', () async {
      final harness = nearbyHarness(
        access: LocationAccess.askable,
        answer: PromptAnswer.refuse,
        delivery: const FixNever(),
      );
      await open(harness);
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
      expect(harness.geolocation.positionCalls, const CallCount(0));
      expect(harness.time.pendingActions, 0);
    });

    test('an already refused permission still asks the platform', () async {
      final harness = nearbyHarness(
        access: LocationAccess.refused,
        answer: PromptAnswer.refuse,
      );
      await open(harness);
      expect(harness.geolocation.requestCalls, const CallCount(1));
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
    });

    test('a prompt answered with yes goes on to locate', () async {
      final harness = nearbyHarness(
        access: LocationAccess.askable,
        delivery: locatedAt(aarhus),
      );
      await open(harness);
      expect(queries(harness), [query(at: aarhus)]);
    });

    for (final fix in const [ServicesOff(), AccessRefused(), NoFix()]) {
      test('$fix searches at once on the best origin', () async {
        final harness = nearbyHarness(delivery: FixAtOnce(fix: fix));
        await open(harness);
        expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
        expect(harness.time.pendingActions, 0);
      });
    }

    test('a missing fix after the timeout changes nothing', () async {
      final harness = nearbyHarness(
        delivery: const FixAfter(delay: Duration(seconds: 15), fix: NoFix()),
      );
      await open(harness);
      await advance(harness, const Duration(seconds: 15));
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
    });

    test('relocating keeps the last real position', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      final controller = await open(harness);
      harness.geolocation.delivery = const FixNever();
      unawaited(controller.locate());
      await flush();
      await advance(harness, const Duration(seconds: 10));
      expect(queries(harness), [query(at: aarhus), query(at: aarhus)]);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [monday],
          origin: DevicePosition(point: aarhus),
        ),
      );
    });

    test('relocating supersedes the locate still running', () async {
      final harness = nearbyHarness(delivery: const FixNever());
      final controller = await open(harness);
      await advance(harness, const Duration(seconds: 5));
      unawaited(controller.locate());
      await flush();
      await advance(harness, const Duration(seconds: 5));
      expect(queries(harness), isEmpty);
      await advance(harness, const Duration(seconds: 5));
      expect(queries(harness), [query(at: GeoPoint.searchFallback)]);
      expect(started(harness), [
        BusyActivity.locating,
        BusyActivity.locating,
        BusyActivity.findingMeetings,
      ]);
    });
  });

  group('results', () {
    test('an older result is discarded', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      harness.meetingSearch.serveNearby(
        radius: const Km(30),
        result: Ok(value: [friday]),
      );
      final narrow = harness.meetingSearch.holdNearby();
      final controller = await open(harness);
      controller.changeRadius(radius: const Km(30));
      await advance(harness, NearbyMeetingsController.sliderDebounce);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [friday],
          origin: DevicePosition(point: aarhus),
        ),
      );
      narrow.open();
      await flush();
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [friday],
          origin: DevicePosition(point: aarhus),
        ),
      );
      expect(ended(harness), hasLength(started(harness).length));
    });

    test('previous results stay while searching again', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      final controller = await open(harness);
      final wide = harness.meetingSearch.holdNearby();
      controller.changeRadius(radius: const Km(30));
      await advance(harness, NearbyMeetingsController.sliderDebounce);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [monday],
          origin: DevicePosition(point: aarhus),
        ),
      );
      wide.open();
      await flush();
      expect(queries(harness).last, query(at: aarhus, radius: const Km(30)));
    });

    test('a failure can be retried with the same origin and radius', () async {
      final harness = nearbyHarness(
        storedValues: {'searchRange': '25'},
        delivery: locatedAt(aarhus),
      );
      harness.meetingSearch.nearby = const Err(
        error: NetworkFailure(detail: 'offline'),
      );
      final controller = await open(harness);
      expect(stateOf(harness).results, const SearchFailed());
      harness.meetingSearch.nearby = Ok(value: [monday]);
      final retried = controller.retry();
      expect(stateOf(harness).results, const AwaitingFirstResult());
      await retried;
      expect(queries(harness), [
        query(at: aarhus, radius: const Km(25)),
        query(at: aarhus, radius: const Km(25)),
      ]);
      expect(
        stateOf(harness).results,
        Shown(
          meetings: [monday],
          origin: DevicePosition(point: aarhus),
        ),
      );
    });
  });

  group('leaving the page', () {
    test('ends the locate span and ignores a late fix', () async {
      final harness = nearbyHarness(
        delivery: FixAfter(
          delay: const Duration(seconds: 5),
          fix: Located(point: aarhus),
        ),
      );
      final subscription = harness.container.listen(
        nearbyMeetingsProvider,
        (previous, next) {},
      );
      await flush();
      subscription.close();
      await flush();
      expect(ended(harness), [BusyActivity.locating]);
      await advance(harness, const Duration(seconds: 15));
      expect(queries(harness), isEmpty);
      expect(harness.time.pendingActions, 0);
    });

    test('ends a pending search span at once', () async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      final gate = harness.meetingSearch.holdNearby();
      final subscription = harness.container.listen(
        nearbyMeetingsProvider,
        (previous, next) {},
      );
      await flush();
      subscription.close();
      await flush();
      expect(ended(harness), [
        BusyActivity.locating,
        BusyActivity.findingMeetings,
      ]);
      gate.open();
      await flush();
      expect(ended(harness), hasLength(2));
    });
  });

  group('state values', () {
    test('compare by value', () {
      final shown = Shown(meetings: [monday], origin: const DefaultPosition());
      expect(
        shown,
        Shown(meetings: [monday], origin: const DefaultPosition()),
      );
      expect(
        shown.hashCode,
        Shown(meetings: [monday], origin: const DefaultPosition()).hashCode,
      );
      expect(shown, isNot(Shown(meetings: [friday], origin: shown.origin)));
      expect(
        shown,
        isNot(Shown(meetings: [monday, friday], origin: shown.origin)),
      );
      expect(const SearchFailed().hashCode, const SearchFailed().hashCode);
      expect(
        const AwaitingFirstResult().hashCode,
        const AwaitingFirstResult().hashCode,
      );
      const state = NearbyState(
        radius: Km(15),
        results: AwaitingFirstResult(),
      );
      expect(
        state,
        const NearbyState(radius: Km(15), results: AwaitingFirstResult()),
      );
      expect(
        state.hashCode,
        const NearbyState(
          radius: Km(15),
          results: AwaitingFirstResult(),
        ).hashCode,
      );
      expect(state.withRadius(radius: const Km(20)).radius, const Km(20));
    });
  });
}
