import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/maps/map_geometry.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';

@immutable
final class MeetingSpot {
  const MeetingSpot({required this.id, required this.point});

  final MeetingId id;
  final GeoPoint point;

  @override
  int get hashCode => Object.hash(id, point);

  @override
  bool operator ==(Object other) =>
      other is MeetingSpot && other.id == id && other.point == point;

  @override
  String toString() => 'MeetingSpot(${id.value} at $point)';
}

@immutable
sealed class MeetingPin {
  const MeetingPin();

  GeoPoint get point;

  List<MeetingId> get ids;
}

final class SinglePin extends MeetingPin {
  const SinglePin({required this.id, required this.point});

  final MeetingId id;

  @override
  final GeoPoint point;

  @override
  List<MeetingId> get ids => List.unmodifiable([id]);

  @override
  int get hashCode => Object.hash(SinglePin, id, point);

  @override
  bool operator ==(Object other) =>
      other is SinglePin && other.id == id && other.point == point;

  @override
  String toString() => 'SinglePin(${id.value} at $point)';
}

final class SharedPin extends MeetingPin {
  SharedPin({required List<MeetingId> ids, required this.point})
    : ids = List.unmodifiable(ids);

  @override
  final List<MeetingId> ids;

  @override
  final GeoPoint point;

  @override
  int get hashCode => Object.hash(SharedPin, Object.hashAll(ids), point);

  @override
  bool operator ==(Object other) =>
      other is SharedPin &&
      other.point == point &&
      const ListEquality<MeetingId>().equals(other.ids, ids);

  @override
  String toString() =>
      'SharedPin(${ids.map((id) => id.value).join(',')} at $point)';
}

(int, int) _roundedSpot({required GeoPoint point}) => (
  (point.latitude.value * 1000).round(),
  (point.longitude.value * 1000).round(),
);

List<MeetingPin> pinsWithin({
  required List<MeetingSpot> spots,
  required MapBounds bounds,
}) => List.unmodifiable(
  spots
      .where(
        (spot) =>
            bounds.membershipOf(point: spot.point) == BoundsMembership.inside,
      )
      .splitBetween(
        (previous, next) =>
            _roundedSpot(point: previous.point) !=
            _roundedSpot(point: next.point),
      )
      .map(
        (group) => group.length == 1
            ? SinglePin(id: group.first.id, point: group.first.point)
            : SharedPin(
                ids: group.map((spot) => spot.id).toList(),
                point: group.first.point,
              ),
      ),
);
