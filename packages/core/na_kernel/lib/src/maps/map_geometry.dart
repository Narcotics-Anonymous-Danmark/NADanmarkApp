import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';

extension type const MapZoom(double value) {
  static const MapZoom initial = MapZoom(8);
  static const MapZoom place = MapZoom(10);
  static const MapZoom clusteringLimit = MapZoom(15);
}

extension type const Metres(double value) {
  double get km => value / 1000;
}

enum MyLocationLayer { shown, hidden }

enum BoundsMembership { inside, outside }

enum SearchNeed { due, notDue }

@immutable
final class MapCamera {
  const MapCamera({required this.target, required this.zoom});

  final GeoPoint target;
  final MapZoom zoom;

  @override
  int get hashCode => Object.hash(target, zoom);

  @override
  bool operator ==(Object other) =>
      other is MapCamera && other.target == target && other.zoom == zoom;

  @override
  String toString() => 'MapCamera($target @ ${zoom.value})';
}

@immutable
final class MapBounds {
  const MapBounds({required this.southWest, required this.northEast});

  factory MapBounds.around({required List<GeoPoint> points}) => MapBounds(
    southWest: GeoPoint(
      latitude: Latitude(points.map((p) => p.latitude.value).reduce(math.min)),
      longitude: Longitude(
        points.map((p) => p.longitude.value).reduce(math.min),
      ),
    ),
    northEast: GeoPoint(
      latitude: Latitude(points.map((p) => p.latitude.value).reduce(math.max)),
      longitude: Longitude(
        points.map((p) => p.longitude.value).reduce(math.max),
      ),
    ),
  );

  final GeoPoint southWest;
  final GeoPoint northEast;

  GeoPoint get farLeft =>
      GeoPoint(latitude: northEast.latitude, longitude: southWest.longitude);

  BoundsMembership membershipOf({required GeoPoint point}) =>
      point.latitude.value >= southWest.latitude.value &&
          point.latitude.value <= northEast.latitude.value &&
          point.longitude.value >= southWest.longitude.value &&
          point.longitude.value <= northEast.longitude.value
      ? BoundsMembership.inside
      : BoundsMembership.outside;

  @override
  int get hashCode => Object.hash(southWest, northEast);

  @override
  bool operator ==(Object other) =>
      other is MapBounds &&
      other.southWest == southWest &&
      other.northEast == northEast;

  @override
  String toString() => 'MapBounds($southWest – $northEast)';
}

final class GreatCircle {
  const GreatCircle();

  static const Metres earthRadius = Metres(6371009);

  Metres between({required GeoPoint from, required GeoPoint to}) {
    final lat1 = _radians(degrees: from.latitude.value);
    final lat2 = _radians(degrees: to.latitude.value);
    final dLat = lat2 - lat1;
    final dLng = _radians(degrees: to.longitude.value - from.longitude.value);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return Metres(2 * earthRadius.value * math.asin(math.min(1, math.sqrt(h))));
  }

  static double _radians({required double degrees}) => degrees * math.pi / 180;
}

extension type const MapRadius(double km) {
  MapRadius.auto({required GeoPoint target, required GeoPoint farLeft})
    : this(const GreatCircle().between(from: target, to: farLeft).km * margin);

  static const double margin = 1.1;
  static const int reSearchDivisor = 11;

  String get code {
    final rounded = (km * 1000).round() / 1000;
    return rounded == rounded.truncateToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}

@immutable
final class SearchedArea {
  const SearchedArea({
    required this.centre,
    required this.zoom,
    required this.radius,
  });

  final GeoPoint centre;
  final MapZoom zoom;
  final MapRadius radius;

  SearchNeed needFor({required MapCamera camera}) =>
      const GreatCircle().between(from: centre, to: camera.target).km >
              radius.km / MapRadius.reSearchDivisor ||
          camera.zoom.value < zoom.value
      ? SearchNeed.due
      : SearchNeed.notDue;

  @override
  int get hashCode => Object.hash(centre, zoom, radius);

  @override
  bool operator ==(Object other) =>
      other is SearchedArea &&
      other.centre == centre &&
      other.zoom == zoom &&
      other.radius == radius;

  @override
  String toString() =>
      'SearchedArea($centre @ ${zoom.value}, ${radius.code} km)';
}
