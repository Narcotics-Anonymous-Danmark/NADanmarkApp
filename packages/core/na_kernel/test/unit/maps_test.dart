@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const GeoPoint copenhagen = GeoPoint(
  latitude: Latitude(55.6761),
  longitude: Longitude(12.5683),
);

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.1629),
  longitude: Longitude(10.2039),
);

const double degreesPerKm = 0.008993203354928916;

GeoPoint at(double latitude, double longitude) =>
    GeoPoint(latitude: Latitude(latitude), longitude: Longitude(longitude));

GeoPoint northOf(GeoPoint point, {required double km}) => at(
  point.latitude.value + km * degreesPerKm,
  point.longitude.value,
);

MeetingSpot spot(int id, double latitude, double longitude) =>
    MeetingSpot(id: MeetingId(id), point: at(latitude, longitude));

const MapBounds denmark = MapBounds(
  southWest: GeoPoint(latitude: Latitude(54), longitude: Longitude(8)),
  northEast: GeoPoint(latitude: Latitude(58), longitude: Longitude(13)),
);

SinglePin single(int id, GeoPoint point) =>
    SinglePin(id: MeetingId(id), point: point);

List<MeetingPin> pinsNear(GeoPoint point, {required int count}) =>
    List.generate(
      count,
      (index) => single(
        index + 1,
        at(point.latitude.value + index * 0.0001, point.longitude.value),
      ),
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
  group('Great-circle distance', () {
    test('uses the Maps SDK earth radius', () {
      expect(
        const GreatCircle().between(from: copenhagen, to: aarhus).value,
        closeTo(156942.945, 0.01),
      );
    });

    test('is zero for the same point', () {
      expect(
        const GreatCircle().between(from: aarhus, to: aarhus).value,
        0,
      );
    });
  });

  group('Auto radius', () {
    test('is 1.1 times the distance to the far-left corner', () {
      final radius = MapRadius.auto(
        target: GeoPoint.searchFallback,
        farLeft: northOf(GeoPoint.searchFallback, km: 20),
      );
      expect(radius.km, closeTo(22, 0.000001));
      expect(radius.code, '22');
    });

    test('codes keep at most three decimals', () {
      expect(const MapRadius(15.51234).code, '15.512');
      expect(const MapRadius(15.5).code, '15.5');
      expect(const MapRadius(22.000000000000004).code, '22');
    });
  });

  group('Bounds', () {
    test('far left is the north-west corner', () {
      expect(denmark.farLeft, at(58, 8));
    });

    test('membership is inclusive', () {
      expect(denmark.membershipOf(point: at(54, 8)), BoundsMembership.inside);
      expect(
        denmark.membershipOf(point: copenhagen),
        BoundsMembership.inside,
      );
      expect(
        denmark.membershipOf(point: at(59, 10)),
        BoundsMembership.outside,
      );
      expect(
        denmark.membershipOf(point: at(56, 14)),
        BoundsMembership.outside,
      );
    });

    test('around spans the given points', () {
      expect(
        MapBounds.around(points: const [copenhagen, aarhus]),
        const MapBounds(
          southWest: GeoPoint(
            latitude: Latitude(55.6761),
            longitude: Longitude(10.2039),
          ),
          northEast: GeoPoint(
            latitude: Latitude(56.1629),
            longitude: Longitude(12.5683),
          ),
        ),
      );
    });

    test('bounds and cameras have value semantics', () {
      expectValueSemantics<MapBounds>(
        build: () => denmark,
        different: const MapBounds(southWest: aarhus, northEast: copenhagen),
      );
      expectValueSemantics<MapCamera>(
        build: () => const MapCamera(target: aarhus, zoom: MapZoom.initial),
        different: const MapCamera(target: aarhus, zoom: MapZoom.place),
      );
    });
  });

  group('Re-search rule', () {
    const searched = SearchedArea(
      centre: GeoPoint.searchFallback,
      zoom: MapZoom(10),
      radius: MapRadius(22),
    );

    test('a small pan keeps the pins', () {
      expect(
        searched.needFor(
          camera: MapCamera(
            target: northOf(GeoPoint.searchFallback, km: 1),
            zoom: const MapZoom(10),
          ),
        ),
        SearchNeed.notDue,
      );
    });

    test('a pan beyond a radius / 11 re-searches', () {
      expect(
        searched.needFor(
          camera: MapCamera(
            target: northOf(GeoPoint.searchFallback, km: 3),
            zoom: const MapZoom(10),
          ),
        ),
        SearchNeed.due,
      );
    });

    test('zooming out re-searches, zooming in does not', () {
      expect(
        searched.needFor(
          camera: const MapCamera(
            target: GeoPoint.searchFallback,
            zoom: MapZoom(9),
          ),
        ),
        SearchNeed.due,
      );
      expect(
        searched.needFor(
          camera: const MapCamera(
            target: GeoPoint.searchFallback,
            zoom: MapZoom(11),
          ),
        ),
        SearchNeed.notDue,
      );
    });

    test('a searched area has value semantics', () {
      expectValueSemantics<SearchedArea>(
        build: () => searched,
        different: const SearchedArea(
          centre: GeoPoint.searchFallback,
          zoom: MapZoom(10),
          radius: MapRadius(30),
        ),
      );
    });
  });

  group('Pins for visible meetings', () {
    test('co-located consecutive meetings become one shared pin', () {
      final pins = pinsWithin(
        spots: [
          spot(1, 55.6761, 12.5683),
          spot(2, 55.6762, 12.5683),
          spot(3, 55.6761, 12.5684),
        ],
        bounds: denmark,
      );
      expect(pins, [
        SharedPin(
          ids: const [MeetingId(1), MeetingId(2), MeetingId(3)],
          point: at(55.6761, 12.5683),
        ),
      ]);
    });

    test('distinct meetings get single pins', () {
      final pins = pinsWithin(
        spots: [spot(1, 55.6761, 12.5683), spot(2, 55.6806, 12.5683)],
        bounds: denmark,
      );
      expect(pins, [
        single(1, at(55.6761, 12.5683)),
        single(2, at(55.6806, 12.5683)),
      ]);
    });

    test('meetings outside the view are dropped before grouping', () {
      final pins = pinsWithin(
        spots: [
          spot(1, 59, 12.5683),
          spot(2, 55.6761, 12.5683),
          spot(3, 55.6761, 12.5683),
        ],
        bounds: denmark,
      );
      expect(pins, [
        SharedPin(
          ids: const [MeetingId(2), MeetingId(3)],
          point: at(55.6761, 12.5683),
        ),
      ]);
    });

    test('only consecutive meetings are grouped', () {
      final pins = pinsWithin(
        spots: [
          spot(1, 55.6761, 12.5683),
          spot(2, 56.1629, 10.2039),
          spot(3, 55.6761, 12.5683),
        ],
        bounds: denmark,
      );
      expect(pins, hasLength(3));
      expect(pins.map((pin) => pin.ids), [
        [const MeetingId(1)],
        [const MeetingId(2)],
        [const MeetingId(3)],
      ]);
    });

    test('pins and spots have value semantics', () {
      expectValueSemantics<MeetingSpot>(
        build: () => spot(1, 55, 10),
        different: spot(2, 55, 10),
      );
      expectValueSemantics<MeetingPin>(
        build: () => single(1, aarhus),
        different: single(1, copenhagen),
      );
      expectValueSemantics<MeetingPin>(
        build: () => SharedPin(
          ids: const [MeetingId(1), MeetingId(2)],
          point: aarhus,
        ),
        different: SharedPin(ids: const [MeetingId(1)], point: aarhus),
      );
    });
  });

  group('Clustering', () {
    const clusterer = MarkerClusterer();
    const zoom = MapZoom(10);

    test('three close pins become one m1 cluster labelled 3', () {
      final markers = clusterer.cluster(
        pins: pinsNear(aarhus, count: 3),
        zoom: zoom,
      );
      expect(markers, hasLength(1));
      final cluster = markers.single as ClusterMarker;
      expect(cluster.meetings, const MeetingCount(3));
      expect(cluster.bucket, ClusterBucket.m1);
      expect(cluster.key, const MarkerKey('cluster-1'));
    });

    test('two close pins stay pins', () {
      final markers = clusterer.cluster(
        pins: pinsNear(aarhus, count: 2),
        zoom: zoom,
      );
      expect(markers.map((marker) => marker.key), const [
        MarkerKey('pin-1'),
        MarkerKey('pin-2'),
      ]);
    });

    test('a cluster counts every id of a shared pin', () {
      final markers = clusterer.cluster(
        pins: [
          ...pinsNear(aarhus, count: 2),
          SharedPin(
            ids: const [MeetingId(7), MeetingId(8), MeetingId(9)],
            point: aarhus,
          ),
        ],
        zoom: zoom,
      );
      expect((markers.single as ClusterMarker).meetings, const MeetingCount(5));
    });

    test('nothing clusters from zoom 15', () {
      final markers = clusterer.cluster(
        pins: pinsNear(aarhus, count: 3),
        zoom: MapZoom.clusteringLimit,
      );
      expect(markers.whereType<PinMarker>(), hasLength(3));
    });

    test('far apart pins keep their own cells in first-seen order', () {
      final markers = clusterer.cluster(
        pins: [
          ...pinsNear(copenhagen, count: 1),
          ...pinsNear(aarhus, count: 3).map(
            (pin) => single(pin.ids.single.value + 10, pin.point),
          ),
        ],
        zoom: zoom,
      );
      expect(markers.map((marker) => marker.key), const [
        MarkerKey('pin-1'),
        MarkerKey('cluster-11'),
      ]);
    });

    test('a cluster sits at the average of its pins and fits their bounds', () {
      final cluster = ClusterMarker(
        pins: [single(1, at(56, 10)), single(2, at(56.2, 10.4))],
      );
      expect(cluster.point.latitude.value, closeTo(56.1, 0.0000001));
      expect(cluster.point.longitude.value, closeTo(10.2, 0.0000001));
      expect(
        cluster.bounds,
        MapBounds(southWest: at(56, 10), northEast: at(56.2, 10.4)),
      );
    });

    test('buckets follow the meeting count', () {
      const edges = {
        3: ClusterBucket.m1,
        10: ClusterBucket.m1,
        11: ClusterBucket.m2,
        50: ClusterBucket.m2,
        51: ClusterBucket.m3,
        100: ClusterBucket.m3,
        101: ClusterBucket.m4,
        500: ClusterBucket.m4,
        501: ClusterBucket.m5,
        2000: ClusterBucket.m5,
      };
      for (final MapEntry(:key, :value) in edges.entries) {
        expect(ClusterBucket.of(meetings: MeetingCount(key)), value);
      }
    });

    test('markers have value semantics', () {
      expectValueSemantics<MapMarker>(
        build: () => PinMarker(pin: single(1, aarhus)),
        different: PinMarker(pin: single(2, aarhus)),
      );
      expectValueSemantics<MapMarker>(
        build: () => ClusterMarker(pins: pinsNear(aarhus, count: 3)),
        different: ClusterMarker(pins: pinsNear(aarhus, count: 4)),
      );
      expectValueSemantics<MapMarker>(
        build: () => const PlaceMarker(
          description: PlaceDescription('Aarhus, Denmark'),
          point: aarhus,
        ),
        different: const PlaceMarker(
          description: PlaceDescription('Aarhus C'),
          point: aarhus,
        ),
      );
      expect(
        const PlaceMarker(
          description: PlaceDescription('Aarhus'),
          point: aarhus,
        ).key,
        MarkerKey.place,
      );
    });
  });

  group('Places', () {
    test('predictions have value semantics', () {
      expectValueSemantics<PlacePrediction>(
        build: () => const PlacePrediction(
          id: PlaceId('a'),
          description: PlaceDescription('Aarhus'),
        ),
        different: const PlacePrediction(
          id: PlaceId('b'),
          description: PlaceDescription('Aarhus'),
        ),
      );
    });
  });
}
