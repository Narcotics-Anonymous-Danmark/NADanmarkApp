@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.15),
  longitude: Longitude(10.2),
);

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
  group('Position fixes', () {
    test('a located fix compares by its point', () {
      expectValueSemantics<PositionFix>(
        build: () => const Located(point: aarhus),
        different: const Located(point: GeoPoint.searchFallback),
      );
    });

    test('the fixes without a point are distinct values', () {
      expectValueSemantics<PositionFix>(
        build: () => const ServicesOff(),
        different: const AccessRefused(),
      );
      expectValueSemantics<PositionFix>(
        build: () => const AccessRefused(),
        different: const NoFix(),
      );
      expectValueSemantics<PositionFix>(
        build: () => const NoFix(),
        different: const ServicesOff(),
      );
    });
  });

  group('Search origins', () {
    test('a device position compares by its point', () {
      expectValueSemantics<SearchOrigin>(
        build: () => const DevicePosition(point: aarhus),
        different: const DefaultPosition(),
      );
      expectValueSemantics<SearchOrigin>(
        build: () => const DefaultPosition(),
        different: const DevicePosition(point: GeoPoint.searchFallback),
      );
    });

    test('the default position resolves to the legacy coordinates', () {
      final point = const DefaultPosition().point;
      expect(point.latitude, const Latitude(55.476224));
      expect(point.longitude, const Longitude(8.4606976));
    });

    test('a device position resolves to its own point', () {
      expect(const DevicePosition(point: aarhus).point, aarhus);
    });
  });

  group('Busy spans', () {
    test(
      'a span publishes one start and one end however often it ends',
      () async {
        final bus = BroadcastEventBus();
        final seen = <DomainEvent>[];
        final subscription = bus.all.listen(seen.add);
        final span = BusyTracker(bus: bus).begin(
          activity: BusyActivity.locating,
        );
        expect(span.state, BusySpanState.open);
        span
          ..end()
          ..end();
        expect(span.state, BusySpanState.ended);
        await Future<void>.delayed(Duration.zero);
        expect(seen, [isA<BusyStarted>(), isA<BusyEnded>()]);
        await subscription.cancel();
        await bus.dispose();
      },
    );

    test('a span ends with the activity it started with', () async {
      final bus = BroadcastEventBus();
      final ended = bus.on<BusyEnded>().first;
      BusyTracker(bus: bus).begin(activity: BusyActivity.locating).end();
      expect((await ended).activity, BusyActivity.locating);
      await bus.dispose();
    });
  });
}
