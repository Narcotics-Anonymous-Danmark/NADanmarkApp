import 'package:adapter_places/src/places_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

enum PlacesContext { autocomplete, details }

final class DioPlaces implements PlacesPort {
  const DioPlaces({required this.dio, required this.endpoints});

  static const WireJson _wire = WireJson();
  static const PlacesMapper _mapper = PlacesMapper();

  final Dio dio;
  final PlacesEndpoints endpoints;

  @override
  Future<Outcome<List<PlacePrediction>, Failure>> predictions({
    required PlaceQuery query,
    required Language language,
  }) async => switch (await _get(
    uri: endpoints.autocomplete(query: query, language: language),
    context: PlacesContext.autocomplete,
  )) {
    Ok(:final value) => _mapper.predictions(json: value),
    Err(:final error) => Err(error: error),
  };

  @override
  Future<Outcome<GeoPoint, Failure>> locate({required PlaceId place}) async =>
      switch (await _get(
        uri: endpoints.details(place: place),
        context: PlacesContext.details,
      )) {
        Ok(:final value) => _mapper.location(json: value),
        Err(:final error) => Err(error: error),
      };

  Future<Outcome<Object?, Failure>> _get({
    required Uri uri,
    required PlacesContext context,
  }) async {
    final String? body;
    try {
      final response = await dio.getUri<String>(
        uri,
        options: Options(responseType: ResponseType.plain),
      );
      body = response.data;
    } on DioException catch (error) {
      return Err(
        error: NetworkFailure(detail: '${context.name}: ${error.type.name}'),
      );
    }
    return switch (_wire.parse(text: body ?? '', context: context.name)) {
      Ok(:final value) => Ok(value: value),
      Err(:final error) => Err(error: error),
    };
  }
}
