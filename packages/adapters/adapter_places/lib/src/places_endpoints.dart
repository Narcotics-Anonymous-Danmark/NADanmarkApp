import 'package:na_kernel/na_kernel.dart';

extension type const PlacesBaseUrl(String value) {}

extension type const MapsApiKey(String value) {}

final class PlacesEndpoints {
  const PlacesEndpoints({required this.base, required this.key});

  static const PlacesBaseUrl google = PlacesBaseUrl(
    'https://maps.googleapis.com/maps/api/place/',
  );

  final PlacesBaseUrl base;
  final MapsApiKey key;

  Uri autocomplete({required PlaceQuery query, required Language language}) =>
      Uri.parse('${base.value}autocomplete/json').replace(
        queryParameters: {
          'input': query.value,
          'language': language.code,
          'key': key.value,
        },
      );

  Uri details({required PlaceId place}) =>
      Uri.parse('${base.value}details/json').replace(
        queryParameters: {
          'place_id': place.value,
          'fields': 'geometry',
          'key': key.value,
        },
      );
}
