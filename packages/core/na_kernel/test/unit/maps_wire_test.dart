@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const BmltMapper bmlt = BmltMapper();
const PlacesMapper places = PlacesMapper();

List<MeetingSpot> spotsOf(Outcome<List<MeetingSpot>, DecodeFailure> decoded) =>
    switch (decoded) {
      Ok(:final value) => value,
      Err(:final error) => fail('$error'),
    };

List<PlacePrediction> predictionsOf(
  Outcome<List<PlacePrediction>, Failure> decoded,
) => switch (decoded) {
  Ok(:final value) => value,
  Err(:final error) => fail('$error'),
};

void main() {
  group('Pins query rows', () {
    test('rows decode to spots in response order', () {
      expect(
        spotsOf(
          bmlt.spots(
            json: const [
              {
                'id_bigint': '43394',
                'longitude': '12.5165555',
                'latitude': '55.6491213',
              },
              {'id_bigint': 43355, 'longitude': 12.5241969, 'latitude': 55.665},
            ],
          ),
        ),
        const [
          MeetingSpot(
            id: MeetingId(43394),
            point: GeoPoint(
              latitude: Latitude(55.6491213),
              longitude: Longitude(12.5165555),
            ),
          ),
          MeetingSpot(
            id: MeetingId(43355),
            point: GeoPoint(
              latitude: Latitude(55.665),
              longitude: Longitude(12.5241969),
            ),
          ),
        ],
      );
    });

    test('rows without coordinates or id are skipped', () {
      final decoded = bmlt.spots(
        json: const [
          {'id_bigint': '1', 'longitude': '12.5', 'latitude': ''},
          {'id_bigint': '2', 'longitude': 'x', 'latitude': '55.6'},
          {'id_bigint': '', 'longitude': '12.5', 'latitude': '55.6'},
          {'id_bigint': '4', 'longitude': '12.5', 'latitude': '55.6'},
        ],
      );
      expect(spotsOf(decoded).map((spot) => spot.id), [const MeetingId(4)]);
    });

    test('an empty object or list is no spots', () {
      expect(spotsOf(bmlt.spots(json: const <String, Object?>{})), isEmpty);
      expect(spotsOf(bmlt.spots(json: const <Object?>[])), isEmpty);
    });

    test('anything else is a decode failure', () {
      expect(
        bmlt.spots(json: 'nope'),
        isA<Err<List<MeetingSpot>, DecodeFailure>>(),
      );
    });
  });

  group('Places autocomplete', () {
    test('OK lists the predictions with id and description', () {
      expect(
        predictionsOf(
          places.predictions(
            json: const {
              'status': 'OK',
              'predictions': [
                {
                  'description': 'Aarhus, Denmark',
                  'place_id': 'ChIJi3iXU7FMTEYRr6IukdnXTYw',
                },
                {'description': '', 'place_id': 'broken'},
              ],
            },
          ),
        ),
        const [
          PlacePrediction(
            id: PlaceId('ChIJi3iXU7FMTEYRr6IukdnXTYw'),
            description: PlaceDescription('Aarhus, Denmark'),
          ),
        ],
      );
    });

    test('ZERO_RESULTS is an empty list', () {
      expect(
        predictionsOf(
          places.predictions(
            json: const {'status': 'ZERO_RESULTS', 'predictions': <Object?>[]},
          ),
        ),
        isEmpty,
      );
    });

    test('any other status is unavailable', () {
      expect(
        places.predictions(json: const {'status': 'REQUEST_DENIED'}),
        const Err<List<PlacePrediction>, Failure>(
          error: UnavailableFailure(what: 'autocomplete: REQUEST_DENIED'),
        ),
      );
    });

    test('a wrong shape is a decode failure', () {
      expect(
        places.predictions(json: const [1, 2]),
        isA<Err<List<PlacePrediction>, Failure>>(),
      );
      expect(
        places.predictions(
          json: const {'status': 'OK', 'predictions': 'nope'},
        ),
        isA<Err<List<PlacePrediction>, Failure>>(),
      );
    });
  });

  group('Place details', () {
    test('OK gives the geometry location', () {
      expect(
        places.location(
          json: const {
            'status': 'OK',
            'result': {
              'geometry': {
                'location': {'lat': 56.162939, 'lng': 10.203921},
              },
            },
          },
        ),
        const Ok<GeoPoint, Failure>(
          value: GeoPoint(
            latitude: Latitude(56.162939),
            longitude: Longitude(10.203921),
          ),
        ),
      );
    });

    test('a missing location is a decode failure', () {
      expect(
        places.location(
          json: const {'status': 'OK', 'result': <String, Object?>{}},
        ),
        isA<Err<GeoPoint, Failure>>().having(
          (err) => err.error,
          'error',
          isA<DecodeFailure>(),
        ),
      );
    });

    test('another status is unavailable and a wrong shape fails', () {
      expect(
        places.location(json: const {'status': 'NOT_FOUND'}),
        const Err<GeoPoint, Failure>(
          error: UnavailableFailure(what: 'details: NOT_FOUND'),
        ),
      );
      expect(places.location(json: 'x'), isA<Err<GeoPoint, Failure>>());
    });

    test('the wire DTOs round trip', () {
      const dto = PlaceDetailsDto(
        status: 'OK',
        result: PlaceResultDto(
          geometry: PlaceGeometryDto(
            location: PlaceLocationDto(lat: '1.5', lng: '2.5'),
          ),
        ),
      );
      expect(PlaceDetailsDto.fromJson(dto.toJson()).toJson(), dto.toJson());
      const autocomplete = PlacesAutocompleteDto(
        status: 'OK',
        predictions: [PlacePredictionDto(description: 'a', placeId: 'b')],
      );
      expect(
        PlacesAutocompleteDto.fromJson(autocomplete.toJson()).toJson(),
        autocomplete.toJson(),
      );
      const spot = BmltSpotDto(idBigint: '1', latitude: '2', longitude: '3');
      expect(BmltSpotDto.fromJson(spot.toJson()).toJson(), spot.toJson());
    });
  });
}
