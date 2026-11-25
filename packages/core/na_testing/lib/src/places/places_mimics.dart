import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/meetings/meeting_port_mimics.dart';

@immutable
final class KnownPlace {
  const KnownPlace({
    required this.id,
    required this.description,
    required this.point,
  });

  final PlaceId id;
  final PlaceDescription description;
  final GeoPoint point;

  PlacePrediction get prediction =>
      PlacePrediction(id: id, description: description);

  @override
  int get hashCode => Object.hash(id, description, point);

  @override
  bool operator ==(Object other) =>
      other is KnownPlace &&
      other.id == id &&
      other.description == description &&
      other.point == point;

  @override
  String toString() => 'KnownPlace(${description.value})';
}

const KnownPlace aarhusPlace = KnownPlace(
  id: PlaceId('ChIJi3iXU7FMTEYRr6IukdnXTYw'),
  description: PlaceDescription('Aarhus, Denmark'),
  point: GeoPoint(
    latitude: Latitude(56.162939),
    longitude: Longitude(10.203921),
  ),
);

const KnownPlace aarhusCentrePlace = KnownPlace(
  id: PlaceId('ChIJ-aarhus-c'),
  description: PlaceDescription('Aarhus C, Aarhus, Denmark'),
  point: GeoPoint(latitude: Latitude(56.1572), longitude: Longitude(10.2107)),
);

const KnownPlace odensePlace = KnownPlace(
  id: PlaceId('ChIJ-odense'),
  description: PlaceDescription('Odense, Denmark'),
  point: GeoPoint(latitude: Latitude(55.4038), longitude: Longitude(10.4024)),
);

const List<KnownPlace> knownPlaces = [
  aarhusPlace,
  aarhusCentrePlace,
  odensePlace,
];

List<PlacePrediction> predictionsFor({required PlaceQuery query}) =>
    List.unmodifiable(
      knownPlaces
          .where(
            (place) => place.description.value.toLowerCase().startsWith(
              query.value.toLowerCase(),
            ),
          )
          .map((place) => place.prediction),
    );

@immutable
final class PredictionsQuery {
  const PredictionsQuery({required this.query, required this.language});

  final PlaceQuery query;
  final Language language;

  @override
  int get hashCode => Object.hash(query, language);

  @override
  bool operator ==(Object other) =>
      other is PredictionsQuery &&
      other.query == query &&
      other.language == language;

  @override
  String toString() => 'PredictionsQuery(${query.value}, ${language.name})';
}

final class PlacesMimic implements PlacesPort {
  final List<PredictionsQuery> predictionQueries = [];
  final List<PlaceId> locateQueries = [];
  final List<PortGate> _predictionGates = [];
  final List<Outcome<List<PlacePrediction>, Failure>> _queuedPredictions = [];
  Outcome<GeoPoint, Failure> located = const Err(
    error: UnavailableFailure(what: 'no place'),
  );
  PlacesAnswer answer = PlacesAnswer.known;

  PortGate holdPredictions() {
    final gate = PortGate();
    _predictionGates.add(gate);
    return gate;
  }

  void queuePredictions({
    required Outcome<List<PlacePrediction>, Failure> result,
  }) => _queuedPredictions.add(result);

  @override
  Future<Outcome<List<PlacePrediction>, Failure>> predictions({
    required PlaceQuery query,
    required Language language,
  }) async {
    predictionQueries.add(
      PredictionsQuery(query: query, language: language),
    );
    final result = _queuedPredictions.isEmpty
        ? switch (answer) {
            PlacesAnswer.known => Ok<List<PlacePrediction>, Failure>(
              value: predictionsFor(query: query),
            ),
            PlacesAnswer.failing => const Err<List<PlacePrediction>, Failure>(
              error: UnavailableFailure(what: 'autocomplete: mimic'),
            ),
          }
        : _queuedPredictions.removeAt(0);
    if (_predictionGates.isNotEmpty) {
      await _predictionGates.removeAt(0).opened;
    }
    return result;
  }

  @override
  Future<Outcome<GeoPoint, Failure>> locate({required PlaceId place}) async {
    locateQueries.add(place);
    return switch (answer) {
      PlacesAnswer.known => switch (knownPlaces.where((p) => p.id == place)) {
        Iterable(isEmpty: false, :final first) => Ok(value: first.point),
        Iterable() => located,
      },
      PlacesAnswer.failing => const Err(
        error: UnavailableFailure(what: 'details: mimic'),
      ),
    };
  }
}

enum PlacesAnswer { known, failing }

sealed class PlacesReply {
  const PlacesReply();
}

final class PlacesFromCatalogue extends PlacesReply {
  const PlacesFromCatalogue();
}

extension type const PlacesStatusCode(String value) {}

final class PlacesStatus extends PlacesReply {
  const PlacesStatus({required this.status});

  final PlacesStatusCode status;
}

final class PlacesUnreachable extends PlacesReply {
  const PlacesUnreachable();
}

final class PlacesMalformed extends PlacesReply {
  const PlacesMalformed();
}

final class PlacesHeld extends PlacesReply {
  PlacesHeld({required this.then});

  final PlacesReply then;
  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();
}

enum PlacesEndpoint { autocomplete, details }

final class PlacesServerMimic implements HttpClientAdapter {
  final List<Uri> requests = [];
  final Map<PlacesEndpoint, PlacesReply> _replies = {
    PlacesEndpoint.autocomplete: const PlacesFromCatalogue(),
    PlacesEndpoint.details: const PlacesFromCatalogue(),
  };

  void serve({required PlacesEndpoint endpoint, required PlacesReply reply}) =>
      _replies[endpoint] = reply;

  PlacesHeld hold({required PlacesEndpoint endpoint}) {
    final held = PlacesHeld(
      then: _replies[endpoint] ?? const PlacesFromCatalogue(),
    );
    _replies[endpoint] = held;
    return held;
  }

  List<Uri> requestsTo({required PlacesEndpoint endpoint}) => List.unmodifiable(
    requests.where((uri) => _endpointOf(uri: uri) == endpoint),
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    final endpoint = _endpointOf(uri: uri);
    return _answer(
      reply: _replies[endpoint] ?? const PlacesFromCatalogue(),
      endpoint: endpoint,
      uri: uri,
      options: options,
    );
  }

  Future<ResponseBody> _answer({
    required PlacesReply reply,
    required PlacesEndpoint endpoint,
    required Uri uri,
    required RequestOptions options,
  }) async {
    switch (reply) {
      case PlacesFromCatalogue():
        return _json(
          body: switch (endpoint) {
            PlacesEndpoint.autocomplete => _autocomplete(
              query: PlaceQuery(uri.queryParameters['input'] ?? ''),
            ),
            PlacesEndpoint.details => _details(
              place: PlaceId(uri.queryParameters['place_id'] ?? ''),
            ),
          },
        );
      case PlacesStatus(:final status):
        return _json(body: jsonEncode({'status': status.value}));
      case PlacesMalformed():
        return _json(body: '<html>');
      case PlacesUnreachable():
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'PlacesServerMimic is unreachable',
        );
      case PlacesHeld(:final then, :final _release):
        await _release.future;
        return _answer(
          reply: then,
          endpoint: endpoint,
          uri: uri,
          options: options,
        );
    }
  }

  static String _autocomplete({required PlaceQuery query}) {
    final predictions = predictionsFor(query: query);
    return jsonEncode(
      PlacesAutocompleteDto(
        status: predictions.isEmpty ? 'ZERO_RESULTS' : 'OK',
        predictions: List.unmodifiable(
          predictions.map(
            (prediction) => PlacePredictionDto(
              description: prediction.description.value,
              placeId: prediction.id.value,
            ),
          ),
        ),
      ).toJson(),
    );
  }

  static String _details({required PlaceId place}) =>
      switch (knownPlaces.where((known) => known.id == place)) {
        Iterable(isEmpty: false, :final first) => jsonEncode(
          PlaceDetailsDto(
            status: 'OK',
            result: PlaceResultDto(
              geometry: PlaceGeometryDto(
                location: PlaceLocationDto(
                  lat: '${first.point.latitude.value}',
                  lng: '${first.point.longitude.value}',
                ),
              ),
            ),
          ).toJson(),
        ),
        Iterable() => jsonEncode({'status': 'NOT_FOUND'}),
      };

  static PlacesEndpoint _endpointOf({required Uri uri}) =>
      uri.path.endsWith('/details/json')
      ? PlacesEndpoint.details
      : PlacesEndpoint.autocomplete;

  static ResponseBody _json({required String body}) => ResponseBody.fromBytes(
    utf8.encode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );

  @override
  void close({bool force = false}) {}
}
