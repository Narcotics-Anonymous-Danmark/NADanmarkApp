import 'package:meta/meta.dart';

extension type const PlaceId(String value) {}

extension type const PlaceQuery(String value) {
  static const PlaceQuery empty = PlaceQuery('');
}

extension type const PlaceDescription(String value) {}

@immutable
final class PlacePrediction {
  const PlacePrediction({required this.id, required this.description});

  final PlaceId id;
  final PlaceDescription description;

  @override
  int get hashCode => Object.hash(id, description);

  @override
  bool operator ==(Object other) =>
      other is PlacePrediction &&
      other.id == id &&
      other.description == description;

  @override
  String toString() => 'PlacePrediction(${description.value})';
}
