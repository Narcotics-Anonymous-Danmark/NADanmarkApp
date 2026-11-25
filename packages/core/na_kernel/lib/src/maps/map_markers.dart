import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/maps/map_geometry.dart';
import 'package:na_kernel/src/maps/meeting_pins.dart';
import 'package:na_kernel/src/maps/places.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';

extension type const MarkerKey(String value) {
  static const MarkerKey place = MarkerKey('place');
}

extension type const MeetingCount(int value) {}

enum ClusterBucket {
  m1(smallest: MeetingCount(3)),
  m2(smallest: MeetingCount(11)),
  m3(smallest: MeetingCount(51)),
  m4(smallest: MeetingCount(101)),
  m5(smallest: MeetingCount(501))
  ;

  const ClusterBucket({required this.smallest});

  final MeetingCount smallest;

  static ClusterBucket of({required MeetingCount meetings}) => values.lastWhere(
    (bucket) => meetings.value >= bucket.smallest.value,
    orElse: () => ClusterBucket.m1,
  );
}

@immutable
sealed class MapMarker {
  const MapMarker();

  MarkerKey get key;

  GeoPoint get point;
}

final class PinMarker extends MapMarker {
  const PinMarker({required this.pin});

  final MeetingPin pin;

  @override
  MarkerKey get key => MarkerKey('pin-${pin.ids.first.value}');

  @override
  GeoPoint get point => pin.point;

  @override
  int get hashCode => Object.hash(PinMarker, pin);

  @override
  bool operator ==(Object other) => other is PinMarker && other.pin == pin;

  @override
  String toString() => 'PinMarker($pin)';
}

final class ClusterMarker extends MapMarker {
  ClusterMarker({required List<MeetingPin> pins})
    : pins = List.unmodifiable(pins);

  final List<MeetingPin> pins;

  @override
  MarkerKey get key => MarkerKey('cluster-${pins.first.ids.first.value}');

  @override
  GeoPoint get point => GeoPoint(
    latitude: Latitude(pins.map((p) => p.point.latitude.value).average),
    longitude: Longitude(pins.map((p) => p.point.longitude.value).average),
  );

  MeetingCount get meetings =>
      MeetingCount(pins.map((pin) => pin.ids.length).sum);

  ClusterBucket get bucket => ClusterBucket.of(meetings: meetings);

  MapBounds get bounds =>
      MapBounds.around(points: pins.map((pin) => pin.point).toList());

  @override
  int get hashCode => Object.hash(ClusterMarker, Object.hashAll(pins));

  @override
  bool operator ==(Object other) =>
      other is ClusterMarker &&
      const ListEquality<MeetingPin>().equals(other.pins, pins);

  @override
  String toString() => 'ClusterMarker(${meetings.value} meetings)';
}

final class PlaceMarker extends MapMarker {
  const PlaceMarker({required this.description, required this.point});

  final PlaceDescription description;

  @override
  final GeoPoint point;

  @override
  MarkerKey get key => MarkerKey.place;

  @override
  int get hashCode => Object.hash(PlaceMarker, description, point);

  @override
  bool operator ==(Object other) =>
      other is PlaceMarker &&
      other.description == description &&
      other.point == point;

  @override
  String toString() => 'PlaceMarker(${description.value} at $point)';
}

final class MarkerClusterer {
  const MarkerClusterer();

  static const double cellPixels = 64;
  static const double tilePixels = 256;
  static const int smallestCluster = 3;

  List<MapMarker> cluster({
    required List<MeetingPin> pins,
    required MapZoom zoom,
  }) => zoom.value >= MapZoom.clusteringLimit.value
      ? List.unmodifiable(pins.map((pin) => PinMarker(pin: pin)))
      : List.unmodifiable(
          groupBy<MeetingPin, (int, int)>(
            pins,
            (pin) => _cellOf(point: pin.point, zoom: zoom),
          ).values.expand(
            (cell) => cell.length >= smallestCluster
                ? [ClusterMarker(pins: cell)]
                : cell.map((pin) => PinMarker(pin: pin)),
          ),
        );

  (int, int) _cellOf({required GeoPoint point, required MapZoom zoom}) {
    final world = tilePixels * math.pow(2, zoom.value);
    final x = (point.longitude.value + 180) / 360 * world;
    final sine = math
        .sin(point.latitude.value * math.pi / 180)
        .clamp(-0.9999, 0.9999);
    final y = (0.5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi)) * world;
    return ((x / cellPixels).floor(), (y / cellPixels).floor());
  }
}
