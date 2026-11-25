import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/maps/places.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

part 'places_wire.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  explicitToJson: true,
  converters: [LenientText()],
)
final class PlacesAutocompleteDto {
  const PlacesAutocompleteDto({this.predictions, this.status});

  factory PlacesAutocompleteDto.fromJson(WireObject json) =>
      _$PlacesAutocompleteDtoFromJson(json);

  final List<PlacePredictionDto>? predictions;
  final String? status;

  WireObject toJson() => _$PlacesAutocompleteDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  fieldRename: FieldRename.snake,
  converters: [LenientText()],
)
final class PlacePredictionDto {
  const PlacePredictionDto({this.description, this.placeId});

  factory PlacePredictionDto.fromJson(WireObject json) =>
      _$PlacePredictionDtoFromJson(json);

  final String? description;
  final String? placeId;

  WireObject toJson() => _$PlacePredictionDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  explicitToJson: true,
  converters: [LenientText()],
)
final class PlaceDetailsDto {
  const PlaceDetailsDto({this.result, this.status});

  factory PlaceDetailsDto.fromJson(WireObject json) =>
      _$PlaceDetailsDtoFromJson(json);

  final PlaceResultDto? result;
  final String? status;

  WireObject toJson() => _$PlaceDetailsDtoToJson(this);
}

@JsonSerializable(checked: true, includeIfNull: false, explicitToJson: true)
final class PlaceResultDto {
  const PlaceResultDto({this.geometry});

  factory PlaceResultDto.fromJson(WireObject json) =>
      _$PlaceResultDtoFromJson(json);

  final PlaceGeometryDto? geometry;

  WireObject toJson() => _$PlaceResultDtoToJson(this);
}

@JsonSerializable(checked: true, includeIfNull: false, explicitToJson: true)
final class PlaceGeometryDto {
  const PlaceGeometryDto({this.location});

  factory PlaceGeometryDto.fromJson(WireObject json) =>
      _$PlaceGeometryDtoFromJson(json);

  final PlaceLocationDto? location;

  WireObject toJson() => _$PlaceGeometryDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class PlaceLocationDto {
  const PlaceLocationDto({this.lat, this.lng});

  factory PlaceLocationDto.fromJson(WireObject json) =>
      _$PlaceLocationDtoFromJson(json);

  final String? lat;
  final String? lng;

  WireObject toJson() => _$PlaceLocationDtoToJson(this);
}

final class PlacesMapper {
  const PlacesMapper();

  static const WireJson _wire = WireJson();
  static const String ok = 'OK';
  static const String zeroResults = 'ZERO_RESULTS';

  Outcome<List<PlacePrediction>, Failure> predictions({
    required Object? json,
  }) => switch (_wire.object(
    json: json,
    fromJson: PlacesAutocompleteDto.fromJson,
    context: 'autocomplete',
  )) {
    Ok(:final value) => switch (value.status) {
      ok => Ok(
        value: List.unmodifiable(
          (value.predictions ?? const <PlacePredictionDto>[])
              .map(prediction)
              .whereType<Ok<PlacePrediction, DecodeFailure>>()
              .map((row) => row.value),
        ),
      ),
      zeroResults => Ok(value: List<PlacePrediction>.unmodifiable([])),
      final String? status => Err(
        error: UnavailableFailure(what: 'autocomplete: $status'),
      ),
    },
    Err(:final error) => Err(error: error),
  };

  Outcome<PlacePrediction, DecodeFailure> prediction(PlacePredictionDto dto) =>
      switch ((dto.placeId?.trim(), dto.description?.trim())) {
        (final String id, final String description)
            when id.isNotEmpty && description.isNotEmpty =>
          Ok(
            value: PlacePrediction(
              id: PlaceId(id),
              description: PlaceDescription(description),
            ),
          ),
        (final String? id, final String? description) => Err(
          error: DecodeFailure(
            detail: 'prediction: id "$id" description "$description"',
          ),
        ),
      };

  Outcome<GeoPoint, Failure> location({required Object? json}) =>
      switch (_wire.object(
        json: json,
        fromJson: PlaceDetailsDto.fromJson,
        context: 'details',
      )) {
        Ok(:final value) => switch (value.status) {
          ok => _point(location: value.result?.geometry?.location),
          final String? status => Err(
            error: UnavailableFailure(what: 'details: $status'),
          ),
        },
        Err(:final error) => Err(error: error),
      };

  Outcome<GeoPoint, Failure> _point({required PlaceLocationDto? location}) =>
      switch ((
        double.tryParse(location?.lat ?? ''),
        double.tryParse(location?.lng ?? ''),
      )) {
        (final double lat, final double lng) => Ok(
          value: GeoPoint(latitude: Latitude(lat), longitude: Longitude(lng)),
        ),
        (final double? lat, final double? lng) => Err(
          error: DecodeFailure(detail: 'details: location $lat, $lng'),
        ),
      };
}
