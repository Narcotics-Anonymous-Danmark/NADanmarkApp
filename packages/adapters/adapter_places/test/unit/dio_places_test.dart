@Tags(['unit'])
library;

import 'package:adapter_places/adapter_places.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/riverpod.dart';

const endpoints = PlacesEndpoints(
  base: PlacesBaseUrl('https://places.test/maps/api/place/'),
  key: MapsApiKey('test-key'),
);

({PlacesServerMimic server, DioPlaces places}) placesAdapter() {
  final server = PlacesServerMimic();
  return (
    server: server,
    places: DioPlaces(
      dio: Dio()..httpClientAdapter = server,
      endpoints: endpoints,
    ),
  );
}

Future<Outcome<List<PlacePrediction>, Failure>> typed(
  DioPlaces places,
  String text,
) => places.predictions(
  query: PlaceQuery(text),
  language: Language.danish,
);

void main() {
  group('Autocomplete', () {
    test('sends the input, the language and the key', () async {
      final subject = placesAdapter();
      await typed(subject.places, 'Aarh ø');
      expect(
        subject.server.requests.single.toString(),
        'https://places.test/maps/api/place/autocomplete/json'
        '?input=Aarh+%C3%B8&language=da&key=test-key',
      );
    });

    test('OK lists the predictions in server order', () async {
      final outcome = await typed(placesAdapter().places, 'Aarh');
      expect((outcome as Ok<List<PlacePrediction>, Failure>).value, [
        aarhusPlace.prediction,
        aarhusCentrePlace.prediction,
      ]);
    });

    test('ZERO_RESULTS is an empty list', () async {
      final outcome = await typed(placesAdapter().places, 'zzqq');
      expect((outcome as Ok<List<PlacePrediction>, Failure>).value, isEmpty);
    });

    test('a denied request is unavailable', () async {
      final subject = placesAdapter();
      subject.server.serve(
        endpoint: PlacesEndpoint.autocomplete,
        reply: const PlacesStatus(status: PlacesStatusCode('REQUEST_DENIED')),
      );
      final outcome = await typed(subject.places, 'Aarh');
      expect(
        (outcome as Err<List<PlacePrediction>, Failure>).error,
        const UnavailableFailure(what: 'autocomplete: REQUEST_DENIED'),
      );
    });

    test('an unreachable server is a network failure', () async {
      final subject = placesAdapter();
      subject.server.serve(
        endpoint: PlacesEndpoint.autocomplete,
        reply: const PlacesUnreachable(),
      );
      final outcome = await typed(subject.places, 'Aarh');
      expect(
        (outcome as Err<List<PlacePrediction>, Failure>).error,
        isA<NetworkFailure>(),
      );
    });

    test('a body that is not JSON is a decode failure', () async {
      final subject = placesAdapter();
      subject.server.serve(
        endpoint: PlacesEndpoint.autocomplete,
        reply: const PlacesMalformed(),
      );
      final outcome = await typed(subject.places, 'Aarh');
      expect(
        (outcome as Err<List<PlacePrediction>, Failure>).error,
        isA<DecodeFailure>(),
      );
    });
  });

  group('Place details', () {
    test('asks for the geometry of the place id', () async {
      final subject = placesAdapter();
      final outcome = await subject.places.locate(place: aarhusPlace.id);
      expect((outcome as Ok<GeoPoint, Failure>).value, aarhusPlace.point);
      expect(
        subject.server.requestsTo(endpoint: PlacesEndpoint.details).single,
        Uri.parse(
          'https://places.test/maps/api/place/details/json'
          '?place_id=${aarhusPlace.id.value}&fields=geometry&key=test-key',
        ),
      );
    });

    test('an unknown place is unavailable', () async {
      final outcome = await placesAdapter().places.locate(
        place: const PlaceId('nowhere'),
      );
      expect(
        (outcome as Err<GeoPoint, Failure>).error,
        const UnavailableFailure(what: 'details: NOT_FOUND'),
      );
    });

    test('an unreachable server is a network failure', () async {
      final subject = placesAdapter();
      subject.server.serve(
        endpoint: PlacesEndpoint.details,
        reply: const PlacesUnreachable(),
      );
      final outcome = await subject.places.locate(place: aarhusPlace.id);
      expect(
        (outcome as Err<GeoPoint, Failure>).error,
        isA<NetworkFailure>(),
      );
    });

    test('a held answer arrives when released', () async {
      final subject = placesAdapter();
      final held = subject.server.hold(endpoint: PlacesEndpoint.details);
      final pending = subject.places.locate(place: aarhusPlace.id);
      held.release();
      expect(
        ((await pending) as Ok<GeoPoint, Failure>).value,
        aarhusPlace.point,
      );
    });
  });

  test('the overrides bind the port', () {
    final container = ProviderContainer(
      overrides: placesOverrides(dio: Dio(), endpoints: endpoints),
    );
    addTearDown(container.dispose);
    expect(container.read(placesPortProvider), isA<DioPlaces>());
  });
}
