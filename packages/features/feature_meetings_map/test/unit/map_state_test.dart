@Tags(['unit'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:feature_meetings_map/feature_meetings_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const MapCamera fallbackCamera = MapCamera(
  target: GeoPoint.searchFallback,
  zoom: MapZoom.initial,
);

void expectValueSemantics<T>({
  required T Function() build,
  required T different,
}) {
  expect(build(), build());
  expect(build().hashCode, build().hashCode);
  expect(build(), isNot(different));
}

Future<void> flush() async {
  for (var turn = 0; turn < 10; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Value semantics', () {
    test('map stages', () {
      expectValueSemantics<MapStage>(
        build: () => const PlacingCamera(),
        different: const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.shown,
        ),
      );
      expectValueSemantics<MapStage>(
        build: () => const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.shown,
        ),
        different: const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.hidden,
        ),
      );
      expect(
        const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.shown,
        ).toString(),
        contains('shown'),
      );
    });

    test('details requests compare by ids and ticket', () {
      final ticket = DetailsTicket();
      final ids = MeetingIds(ids: const [MeetingId(1)]);
      expectValueSemantics<DetailsRequest>(
        build: () => DetailsFor(meetings: ids, ticket: ticket),
        different: DetailsFor(meetings: ids, ticket: DetailsTicket()),
      );
      expectValueSemantics<DetailsRequest>(
        build: () => const NoDetails(),
        different: DetailsFor(meetings: ids, ticket: ticket),
      );
    });

    test('map search states', () {
      MapSearchState state({required MapSearchStatus status}) => MapSearchState(
        stage: const PlacingCamera(),
        markers: const [],
        status: status,
        details: const NoDetails(),
      );
      expectValueSemantics<MapSearchState>(
        build: () => state(status: MapSearchStatus.searched),
        different: state(status: MapSearchStatus.failed),
      );
    });

    test('place suggestions and search states', () {
      expectValueSemantics<PlaceSuggestions>(
        build: () => Suggestions(predictions: [aarhusPlace.prediction]),
        different: const NoSuggestions(),
      );
      expectValueSemantics<PlaceSuggestions>(
        build: () => const NoSuggestions(),
        different: Suggestions(predictions: const []),
      );
      expectValueSemantics<PlaceSearchState>(
        build: () => const PlaceSearchState(
          query: PlaceQuery('Aar'),
          suggestions: NoSuggestions(),
        ),
        different: const PlaceSearchState(
          query: PlaceQuery('Ode'),
          suggestions: NoSuggestions(),
        ),
      );
    });
  });

  group('Before the native map is created', () {
    TestContainer harness() {
      final built = TestContainer.build();
      addTearDown(built.dispose);
      built.geolocation.delivery = const FixNever();
      return built;
    }

    Future<MapSearchController> open(TestContainer built) async {
      final subscription = built.container.listen(
        mapSearchProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await flush();
      return built.read(mapSearchProvider.notifier);
    }

    test('idles, retries and taps do nothing', () async {
      final built = harness();
      final controller = await open(built)
        ..cameraIdle()
        ..markerTapped(marker: MarkerKey.place);
      await controller.retry();
      expect(built.meetingSearch.spotsQueries, isEmpty);
      expect(built.read(mapSearchProvider).details, const NoDetails());
    });

    test('a chosen place is kept until the map exists', () async {
      final built = harness();
      final controller = await open(built);
      await controller.showPlace(
        description: aarhusPlace.description,
        point: aarhusPlace.point,
      );
      expect(built.read(mapSearchProvider).markers, [
        PlaceMarker(
          description: aarhusPlace.description,
          point: aarhusPlace.point,
        ),
      ]);
    });

    test('a drawn map without a handle does not search', () async {
      final built = harness();
      final controller = await open(built);
      built.time.advance(by: const Duration(seconds: 10));
      await flush();
      controller
        ..cameraMoved(camera: fallbackCamera)
        ..cameraIdle();
      await controller.retry();
      expect(built.meetingSearch.spotsQueries, isEmpty);
    });
  });
}
