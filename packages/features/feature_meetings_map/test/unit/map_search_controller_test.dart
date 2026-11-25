@Tags(['unit'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:feature_meetings_map/feature_meetings_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const double degreesPerKm = 0.008993203354928916;

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.15),
  longitude: Longitude(10.2),
);

const MapCamera fallbackCamera = MapCamera(
  target: GeoPoint.searchFallback,
  zoom: MapZoom.initial,
);

GeoPoint offset(GeoPoint from, {double northKm = 0, double eastKm = 0}) =>
    GeoPoint(
      latitude: Latitude(from.latitude.value + northKm * degreesPerKm),
      longitude: Longitude(from.longitude.value + eastKm * degreesPerKm * 1.77),
    );

MeetingSpot spotAt(int id, GeoPoint point) =>
    MeetingSpot(id: MeetingId(id), point: point);

TestContainer mapHarness({
  LocationAccess access = LocationAccess.granted,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
  List<MeetingSpot> spots = const [],
  Map<String, String> storedValues = const {},
}) {
  final harness = TestContainer.build(storedValues: storedValues);
  addTearDown(harness.dispose);
  harness.geolocation
    ..currentAccess = access
    ..delivery = delivery;
  harness.meetingSearch.spots = Ok(value: spots);
  return harness;
}

Future<void> flush() async {
  for (var turn = 0; turn < 10; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> advance(TestContainer harness, Duration by) async {
  harness.time.advance(by: by);
  await flush();
}

Future<MapSearchController> open(TestContainer harness) async {
  final map = harness.container.listen(mapSearchProvider, (previous, next) {});
  final places = harness.container.listen(
    placeSearchProvider,
    (previous, next) {},
  );
  addTearDown(map.close);
  addTearDown(places.close);
  await flush();
  return harness.read(mapSearchProvider.notifier);
}

MapSearchState stateOf(TestContainer harness) =>
    harness.read(mapSearchProvider);

Future<MapSurfaceMimic> drawSurface(
  TestContainer harness, {
  ViewportScript viewport = const ViewportFromZoom(),
}) async {
  final controller = harness.read(mapSearchProvider.notifier);
  final initial = switch (stateOf(harness).stage) {
    MapDrawn(:final initial) => initial,
    PlacingCamera() => fail('map not drawn'),
  };
  final mimic = MapSurfaceMimic(camera: initial)
    ..viewport = viewport
    ..connect(events: controller);
  controller
    ..created(handle: mimic)
    ..cameraMoved(camera: initial)
    ..cameraIdle();
  await flush();
  return mimic;
}

Future<void> moveTo(MapSurfaceMimic mimic, MapCamera camera) async {
  mimic.moveCamera(to: camera);
  await flush();
}

List<SpotsQuery> queries(TestContainer harness) =>
    List.unmodifiable(harness.meetingSearch.spotsQueries);

List<BusyActivity> started(TestContainer harness) => List.unmodifiable(
  harness.events.recordedOf<BusyStarted>().map((event) => event.activity),
);

List<BusyActivity> ended(TestContainer harness) => List.unmodifiable(
  harness.events.recordedOf<BusyEnded>().map((event) => event.activity),
);

List<String> markerKeys(TestContainer harness) =>
    stateOf(harness).markers.map((marker) => marker.key.value).toList();

void main() {
  group('Initial camera', () {
    test('a position in time centres the map at zoom 8', () async {
      final harness = mapHarness(
        delivery: const FixAfter(
          delay: Duration(seconds: 3),
          fix: Located(point: aarhus),
        ),
      );
      await open(harness);
      expect(stateOf(harness).stage, const PlacingCamera());
      expect(started(harness), [BusyActivity.locating]);
      await advance(harness, const Duration(seconds: 3));
      expect(
        stateOf(harness).stage,
        const MapDrawn(
          initial: MapCamera(target: aarhus, zoom: MapZoom.initial),
          myLocation: MyLocationLayer.shown,
        ),
      );
      expect(ended(harness), [BusyActivity.locating]);
    });

    test('a timeout draws the default coordinates', () async {
      final harness = mapHarness(delivery: const FixNever());
      await open(harness);
      await advance(harness, const Duration(seconds: 9));
      expect(stateOf(harness).stage, const PlacingCamera());
      await advance(harness, const Duration(seconds: 1));
      expect(
        stateOf(harness).stage,
        const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.shown,
        ),
      );
      expect(ended(harness), [BusyActivity.locating]);
    });

    test('a fix after the timeout is ignored', () async {
      final harness = mapHarness(
        delivery: const FixAfter(
          delay: Duration(seconds: 15),
          fix: Located(point: aarhus),
        ),
      );
      await open(harness);
      await advance(harness, const Duration(seconds: 20));
      expect(
        (stateOf(harness).stage as MapDrawn).initial,
        fallbackCamera,
      );
    });

    test('a failed fix draws the default coordinates at once', () async {
      final harness = mapHarness();
      await open(harness);
      expect((stateOf(harness).stage as MapDrawn).initial, fallbackCamera);
    });

    test('without permission the map draws without a prompt', () async {
      final harness = mapHarness(access: LocationAccess.askable);
      await open(harness);
      expect(
        stateOf(harness).stage,
        const MapDrawn(
          initial: fallbackCamera,
          myLocation: MyLocationLayer.hidden,
        ),
      );
      expect(harness.geolocation.requestCalls, const CallCount(0));
      expect(harness.geolocation.positionCalls, const CallCount(0));
      expect(started(harness), isEmpty);
    });
  });

  group('Searching', () {
    test('the first idle searches with the auto radius', () async {
      final harness = mapHarness();
      await open(harness);
      await drawSurface(
        harness,
        viewport: ViewportFixed(
          bounds: MapBounds(
            southWest: offset(GeoPoint.searchFallback, northKm: -20),
            northEast: offset(GeoPoint.searchFallback, northKm: 20),
          ),
        ),
      );
      expect(queries(harness).single.centre, GeoPoint.searchFallback);
      expect(queries(harness).single.radius.code, '22');
      expect(stateOf(harness).status, MapSearchStatus.searched);
      expect(
        started(harness).where((a) => a == BusyActivity.findingMeetings),
        hasLength(1),
      );
      expect(
        ended(harness).where((a) => a == BusyActivity.findingMeetings),
        hasLength(1),
      );
    });

    test('a small pan keeps the pins, a large pan searches again', () async {
      final harness = mapHarness();
      await open(harness);
      final mimic = await drawSurface(
        harness,
        viewport: ViewportFixed(
          bounds: MapBounds(
            southWest: offset(GeoPoint.searchFallback, northKm: -20),
            northEast: offset(GeoPoint.searchFallback, northKm: 20),
          ),
        ),
      );
      await moveTo(
        mimic,
        MapCamera(
          target: offset(GeoPoint.searchFallback, northKm: 1),
          zoom: MapZoom.initial,
        ),
      );
      expect(queries(harness), hasLength(1));
      await moveTo(
        mimic,
        MapCamera(
          target: offset(GeoPoint.searchFallback, northKm: 3),
          zoom: MapZoom.initial,
        ),
      );
      expect(queries(harness), hasLength(2));
    });

    test('zooming out searches again, zooming in does not', () async {
      final harness = mapHarness();
      await open(harness);
      final mimic = await drawSurface(harness);
      await moveTo(
        mimic,
        const MapCamera(target: GeoPoint.searchFallback, zoom: MapZoom(9)),
      );
      expect(queries(harness), hasLength(1));
      await moveTo(
        mimic,
        const MapCamera(target: GeoPoint.searchFallback, zoom: MapZoom(7)),
      );
      expect(queries(harness), hasLength(2));
    });

    test('pins are placed for visible spots only', () async {
      final harness = mapHarness(
        spots: [
          spotAt(1, offset(GeoPoint.searchFallback, northKm: 5)),
          spotAt(2, offset(GeoPoint.searchFallback, eastKm: 30)),
          spotAt(3, offset(GeoPoint.searchFallback, northKm: 900)),
        ],
      );
      await open(harness);
      await drawSurface(harness);
      expect(markerKeys(harness), ['pin-1', 'pin-2']);
    });

    test('pins re-cluster after a zoom without a new search', () async {
      final harness = mapHarness(
        spots: [
          spotAt(1, offset(GeoPoint.searchFallback, northKm: 0.2)),
          spotAt(2, offset(GeoPoint.searchFallback, northKm: 0.4)),
          spotAt(3, offset(GeoPoint.searchFallback, northKm: 0.6)),
        ],
      );
      await open(harness);
      final mimic = await drawSurface(harness);
      expect(markerKeys(harness), ['cluster-1']);
      await moveTo(
        mimic,
        const MapCamera(
          target: GeoPoint.searchFallback,
          zoom: MapZoom.clusteringLimit,
        ),
      );
      expect(queries(harness), hasLength(1));
      expect(markerKeys(harness), ['pin-1', 'pin-2', 'pin-3']);
    });

    test('a failure shows the error and retry searches again', () async {
      final harness = mapHarness(
        spots: [spotAt(1, GeoPoint.searchFallback)],
      );
      harness.meetingSearch.queueSpots(
        result: const Err(error: NetworkFailure(detail: 'down')),
      );
      final controller = await open(harness);
      await drawSurface(harness);
      expect(stateOf(harness).status, MapSearchStatus.failed);
      expect(
        ended(harness).where((a) => a == BusyActivity.findingMeetings),
        hasLength(1),
      );
      await controller.retry();
      await flush();
      expect(stateOf(harness).status, MapSearchStatus.searched);
      expect(markerKeys(harness), ['pin-1']);
    });

    test('an older result is discarded', () async {
      final harness = mapHarness();
      harness.meetingSearch
        ..queueSpots(result: Ok(value: [spotAt(1, GeoPoint.searchFallback)]))
        ..queueSpots(
          result: Ok(
            value: [spotAt(2, offset(GeoPoint.searchFallback, northKm: 30))],
          ),
        );
      final gate = harness.meetingSearch.holdSpots();
      await open(harness);
      final mimic = await drawSurface(harness);
      final moved = MapCamera(
        target: offset(GeoPoint.searchFallback, northKm: 30),
        zoom: MapZoom.initial,
      );
      await moveTo(mimic, moved);
      expect(markerKeys(harness), ['pin-2']);
      gate.open();
      await flush();
      expect(markerKeys(harness), ['pin-2']);
    });

    test('leaving during a search ends the loading activity', () async {
      final harness = mapHarness();
      final gate = harness.meetingSearch.holdSpots();
      final map = harness.container.listen(
        mapSearchProvider,
        (previous, next) {},
      );
      await flush();
      await drawSurface(harness);
      expect(started(harness), contains(BusyActivity.findingMeetings));
      map.close();
      await flush();
      expect(ended(harness), contains(BusyActivity.findingMeetings));
      gate.open();
      await flush();
    });
  });

  group('Taps', () {
    test('a pin asks for the details of all its meetings', () async {
      final harness = mapHarness(
        spots: [
          spotAt(7, GeoPoint.searchFallback),
          spotAt(8, GeoPoint.searchFallback),
        ],
      );
      final controller = await open(harness);
      await drawSurface(harness);
      controller.markerTapped(marker: const MarkerKey('pin-7'));
      expect(
        (stateOf(harness).details as DetailsFor).meetings,
        MeetingIds(ids: const [MeetingId(7), MeetingId(8)]),
      );
    });

    test('a cluster fits its pins', () async {
      final harness = mapHarness(
        spots: [
          spotAt(1, offset(GeoPoint.searchFallback, northKm: 0.2)),
          spotAt(2, offset(GeoPoint.searchFallback, northKm: 0.4)),
          spotAt(3, offset(GeoPoint.searchFallback, northKm: 0.6)),
        ],
      );
      final controller = await open(harness);
      final mimic = await drawSurface(harness);
      controller.markerTapped(marker: const MarkerKey('cluster-1'));
      await flush();
      expect(
        mimic.fits.single,
        MapBounds(
          southWest: offset(GeoPoint.searchFallback, northKm: 0.2),
          northEast: offset(GeoPoint.searchFallback, northKm: 0.6),
        ),
      );
      expect(stateOf(harness).details, const NoDetails());
    });

    test('an unknown key does nothing', () async {
      final harness = mapHarness();
      final controller = await open(harness);
      await drawSurface(harness);
      controller.markerTapped(marker: const MarkerKey('pin-404'));
      expect(stateOf(harness).details, const NoDetails());
    });
  });

  group('Places', () {
    test('choosing a place drops a marker and moves to zoom 10', () async {
      final harness = mapHarness();
      await open(harness);
      final mimic = await drawSurface(harness);
      await harness
          .read(placeSearchProvider.notifier)
          .choose(prediction: aarhusPlace.prediction);
      await flush();
      expect(mimic.moves, [
        MapCamera(target: aarhusPlace.point, zoom: MapZoom.place),
      ]);
      expect(
        stateOf(harness).markers.last,
        PlaceMarker(
          description: aarhusPlace.description,
          point: aarhusPlace.point,
        ),
      );
      expect(mimic.infoWindows[MarkerKey.place], InfoWindowState.shown);
      expect(
        harness.read(placeSearchProvider),
        PlaceSearchState(
          query: PlaceQuery(aarhusPlace.description.value),
          suggestions: const NoSuggestions(),
        ),
      );
      expect(queries(harness), hasLength(2));
      harness
          .read(mapSearchProvider.notifier)
          .markerTapped(
            marker: MarkerKey.place,
          );
      await flush();
      expect(mimic.infoWindows[MarkerKey.place], InfoWindowState.hidden);
    });

    test('typing waits 300 ms and asks in the app language', () async {
      final harness = mapHarness(storedValues: {'language': 'en'});
      await open(harness);
      final places = harness.read(placeSearchProvider.notifier)
        ..type(query: const PlaceQuery('A'))
        ..type(query: const PlaceQuery('Aa'))
        ..type(query: const PlaceQuery('Aar'));
      await advance(harness, const Duration(milliseconds: 299));
      expect(harness.places.predictionQueries, isEmpty);
      await advance(harness, const Duration(milliseconds: 1));
      expect(harness.places.predictionQueries, const [
        PredictionsQuery(query: PlaceQuery('Aar'), language: Language.english),
      ]);
      expect(
        harness.read(placeSearchProvider).suggestions,
        Suggestions(
          predictions: [aarhusPlace.prediction, aarhusCentrePlace.prediction],
        ),
      );
      places.type(query: PlaceQuery.empty);
      expect(
        harness.read(placeSearchProvider).suggestions,
        const NoSuggestions(),
      );
    });

    test('clearing before the pause sends nothing', () async {
      final harness = mapHarness();
      await open(harness);
      harness.read(placeSearchProvider.notifier)
        ..type(query: const PlaceQuery('Aar'))
        ..type(query: PlaceQuery.empty);
      await advance(harness, const Duration(seconds: 1));
      expect(harness.places.predictionQueries, isEmpty);
    });

    test('an older answer never replaces a newer one', () async {
      final harness = mapHarness();
      await open(harness);
      final gate = harness.places.holdPredictions();
      final places = harness.read(placeSearchProvider.notifier)
        ..type(query: const PlaceQuery('Aar'));
      await advance(harness, const Duration(milliseconds: 300));
      places.type(query: const PlaceQuery('Ode'));
      await advance(harness, const Duration(milliseconds: 300));
      gate.open();
      await flush();
      expect(
        harness.read(placeSearchProvider).suggestions,
        Suggestions(predictions: [odensePlace.prediction]),
      );
    });

    test('failures show no suggestions and leave the map', () async {
      final harness = mapHarness();
      await open(harness);
      final mimic = await drawSurface(harness);
      harness.places.answer = PlacesAnswer.failing;
      final places = harness.read(placeSearchProvider.notifier)
        ..type(query: const PlaceQuery('Aar'));
      await advance(harness, const Duration(milliseconds: 300));
      expect(
        harness.read(placeSearchProvider).suggestions,
        const NoSuggestions(),
      );
      await places.choose(prediction: aarhusPlace.prediction);
      await flush();
      expect(mimic.moves, isEmpty);
      expect(
        stateOf(harness).markers.whereType<PlaceMarker>(),
        isEmpty,
      );
    });
  });
}
