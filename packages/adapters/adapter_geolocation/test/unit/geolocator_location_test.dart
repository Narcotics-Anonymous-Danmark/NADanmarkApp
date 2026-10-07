@Tags(['unit'])
library;

import 'package:adapter_geolocation/adapter_geolocation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

sealed class PositionAnswer {
  const PositionAnswer();
}

final class AnswerPosition extends PositionAnswer {
  const AnswerPosition({required this.position});

  final Position position;
}

final class AnswerError extends PositionAnswer {
  const AnswerError({required this.error});

  final Exception error;
}

enum LocationServices { enabled, disabled }

extension type const AccuracyMetres(double value) {}

final class GeolocatorPlatformMimic extends GeolocatorPlatform {
  GeolocatorPlatformMimic({
    this.permission = LocationPermission.whileInUse,
    this.promptAnswer = LocationPermission.whileInUse,
    this.services = LocationServices.enabled,
    this.answer = const AnswerError(error: PositionUpdateException('no fix')),
  });

  LocationPermission permission;
  LocationPermission promptAnswer;
  LocationServices services;
  PositionAnswer answer;
  Exception? permissionError;
  final List<LocationSettings?> positionRequests = [];

  @override
  Future<LocationPermission> checkPermission() async =>
      switch (permissionError) {
        final Exception error => throw error,
        null => permission,
      };

  @override
  Future<LocationPermission> requestPermission() async =>
      switch (permissionError) {
        final Exception error => throw error,
        null => permission = promptAnswer,
      };

  @override
  Future<bool> isLocationServiceEnabled() async => switch (services) {
    LocationServices.enabled => true,
    LocationServices.disabled => false,
  };

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests.add(locationSettings);
    return switch (answer) {
      AnswerPosition(:final position) => position,
      AnswerError(:final error) => throw error,
    };
  }
}

Position aPosition({
  Latitude latitude = const Latitude(56.15),
  Longitude longitude = const Longitude(10.2),
  AccuracyMetres accuracy = const AccuracyMetres(15),
}) => Position(
  latitude: latitude.value,
  longitude: longitude.value,
  timestamp: DateTime.utc(2026, 10, 7),
  accuracy: accuracy.value,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.15),
  longitude: Longitude(10.2),
);

void main() {
  group('access', () {
    final cases = <LocationPermission, LocationAccess>{
      LocationPermission.whileInUse: LocationAccess.granted,
      LocationPermission.always: LocationAccess.granted,
      LocationPermission.denied: LocationAccess.askable,
      LocationPermission.unableToDetermine: LocationAccess.askable,
      LocationPermission.deniedForever: LocationAccess.refused,
    };
    for (final MapEntry(key: permission, value: access) in cases.entries) {
      test('$permission reads as $access', () async {
        final location = GeolocatorLocation(
          platform: GeolocatorPlatformMimic(permission: permission),
        );
        expect(await location.access(), access);
      });
    }

    test('a failing permission check reads as askable', () async {
      final platform = GeolocatorPlatformMimic()
        ..permissionError = const PermissionDefinitionsNotFoundException(
          'no manifest entry',
        );
      expect(
        await GeolocatorLocation(platform: platform).access(),
        LocationAccess.askable,
      );
    });
  });

  group('requestAccess', () {
    final cases = <LocationPermission, LocationAccess>{
      LocationPermission.whileInUse: LocationAccess.granted,
      LocationPermission.always: LocationAccess.granted,
      LocationPermission.denied: LocationAccess.refused,
      LocationPermission.deniedForever: LocationAccess.refused,
      LocationPermission.unableToDetermine: LocationAccess.refused,
    };
    for (final MapEntry(key: answer, value: access) in cases.entries) {
      test('answering $answer reads as $access', () async {
        final location = GeolocatorLocation(
          platform: GeolocatorPlatformMimic(
            permission: LocationPermission.denied,
            promptAnswer: answer,
          ),
        );
        expect(await location.requestAccess(), access);
      });
    }

    test('a failing request reads as refused', () async {
      final platform = GeolocatorPlatformMimic()
        ..permissionError = const PermissionRequestInProgressException('busy');
      expect(
        await GeolocatorLocation(platform: platform).requestAccess(),
        LocationAccess.refused,
      );
    });
  });

  group('currentPosition', () {
    test('a position becomes a located fix at medium accuracy', () async {
      final platform = GeolocatorPlatformMimic(
        answer: AnswerPosition(position: aPosition()),
      );
      expect(
        await GeolocatorLocation(platform: platform).currentPosition(),
        const Located(point: aarhus),
      );
      expect(
        platform.positionRequests.single?.accuracy,
        LocationAccuracy.medium,
      );
      expect(platform.positionRequests.single?.timeLimit, isNull);
    });

    test('Approximate location is accepted', () async {
      final platform = GeolocatorPlatformMimic(
        answer: AnswerPosition(
          position: aPosition(
            latitude: const Latitude(56.1),
            longitude: const Longitude(10.3),
            accuracy: const AccuracyMetres(3000),
          ),
        ),
      );
      final location = GeolocatorLocation(platform: platform);
      expect(await location.access(), LocationAccess.granted);
      expect(
        await location.currentPosition(),
        const Located(
          point: GeoPoint(latitude: Latitude(56.1), longitude: Longitude(10.3)),
        ),
      );
    });

    test('disabled services skip the position request', () async {
      final platform = GeolocatorPlatformMimic(
        services: LocationServices.disabled,
      );
      expect(
        await GeolocatorLocation(platform: platform).currentPosition(),
        const ServicesOff(),
      );
      expect(platform.positionRequests, isEmpty);
    });

    test('services switched off while locating read as services off', () async {
      final platform = GeolocatorPlatformMimic(
        answer: const AnswerError(error: LocationServiceDisabledException()),
      );
      expect(
        await GeolocatorLocation(platform: platform).currentPosition(),
        const ServicesOff(),
      );
    });

    test('a permission error reads as access refused', () async {
      final platform = GeolocatorPlatformMimic(
        answer: const AnswerError(error: PermissionDeniedException('denied')),
      );
      expect(
        await GeolocatorLocation(platform: platform).currentPosition(),
        const AccessRefused(),
      );
    });

    test('any other error reads as no fix', () async {
      final platform = GeolocatorPlatformMimic(
        answer: const AnswerError(error: PositionUpdateException('lost')),
      );
      expect(
        await GeolocatorLocation(platform: platform).currentPosition(),
        const NoFix(),
      );
    });
  });

  test('the overrides bind the port to the adapter', () {
    final platform = GeolocatorPlatformMimic();
    final container = ProviderContainer(
      overrides: geolocationOverrides(platform: platform),
    );
    addTearDown(container.dispose);
    expect(
      container.read(geolocationPortProvider),
      isA<GeolocatorLocation>().having(
        (location) => location.platform,
        'platform',
        same(platform),
      ),
    );
  });
}
