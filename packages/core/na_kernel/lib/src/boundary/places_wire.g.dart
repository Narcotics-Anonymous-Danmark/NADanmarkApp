// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlacesAutocompleteDto _$PlacesAutocompleteDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlacesAutocompleteDto', json, ($checkedConvert) {
  final val = PlacesAutocompleteDto(
    predictions: $checkedConvert(
      'predictions',
      (v) => (v as List<dynamic>?)
          ?.map((e) => PlacePredictionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    status: $checkedConvert('status', (v) => const LenientText().fromJson(v)),
  );
  return val;
});

Map<String, dynamic> _$PlacesAutocompleteDtoToJson(
  PlacesAutocompleteDto instance,
) => <String, dynamic>{
  'predictions': ?instance.predictions?.map((e) => e.toJson()).toList(),
  'status': ?const LenientText().toJson(instance.status),
};

PlacePredictionDto _$PlacePredictionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlacePredictionDto', json, ($checkedConvert) {
      final val = PlacePredictionDto(
        description: $checkedConvert(
          'description',
          (v) => const LenientText().fromJson(v),
        ),
        placeId: $checkedConvert(
          'place_id',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'placeId': 'place_id'});

Map<String, dynamic> _$PlacePredictionDtoToJson(PlacePredictionDto instance) =>
    <String, dynamic>{
      'description': ?const LenientText().toJson(instance.description),
      'place_id': ?const LenientText().toJson(instance.placeId),
    };

PlaceDetailsDto _$PlaceDetailsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlaceDetailsDto', json, ($checkedConvert) {
  final val = PlaceDetailsDto(
    result: $checkedConvert(
      'result',
      (v) =>
          v == null ? null : PlaceResultDto.fromJson(v as Map<String, dynamic>),
    ),
    status: $checkedConvert('status', (v) => const LenientText().fromJson(v)),
  );
  return val;
});

Map<String, dynamic> _$PlaceDetailsDtoToJson(PlaceDetailsDto instance) =>
    <String, dynamic>{
      'result': ?instance.result?.toJson(),
      'status': ?const LenientText().toJson(instance.status),
    };

PlaceResultDto _$PlaceResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaceResultDto', json, ($checkedConvert) {
      final val = PlaceResultDto(
        geometry: $checkedConvert(
          'geometry',
          (v) => v == null
              ? null
              : PlaceGeometryDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlaceResultDtoToJson(PlaceResultDto instance) =>
    <String, dynamic>{'geometry': ?instance.geometry?.toJson()};

PlaceGeometryDto _$PlaceGeometryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaceGeometryDto', json, ($checkedConvert) {
      final val = PlaceGeometryDto(
        location: $checkedConvert(
          'location',
          (v) => v == null
              ? null
              : PlaceLocationDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlaceGeometryDtoToJson(PlaceGeometryDto instance) =>
    <String, dynamic>{'location': ?instance.location?.toJson()};

PlaceLocationDto _$PlaceLocationDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaceLocationDto', json, ($checkedConvert) {
      final val = PlaceLocationDto(
        lat: $checkedConvert('lat', (v) => const LenientText().fromJson(v)),
        lng: $checkedConvert('lng', (v) => const LenientText().fromJson(v)),
      );
      return val;
    });

Map<String, dynamic> _$PlaceLocationDtoToJson(PlaceLocationDto instance) =>
    <String, dynamic>{
      'lat': ?const LenientText().toJson(instance.lat),
      'lng': ?const LenientText().toJson(instance.lng),
    };
