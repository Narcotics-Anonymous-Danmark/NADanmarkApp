import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class GeolocatorLocation implements GeolocationPort {
  const GeolocatorLocation({required this.platform});

  final GeolocatorPlatform platform;

  static const LocationSettings settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
  );

  @override
  Future<LocationAccess> access() async {
    try {
      return _accessOf(permission: await platform.checkPermission());
    } on Exception {
      return LocationAccess.askable;
    }
  }

  @override
  Future<LocationAccess> requestAccess() async {
    try {
      return switch (await platform.requestPermission()) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationAccess.granted,
        LocationPermission.denied ||
        LocationPermission.deniedForever ||
        LocationPermission.unableToDetermine => LocationAccess.refused,
      };
    } on Exception {
      return LocationAccess.refused;
    }
  }

  @override
  Future<PositionFix> currentPosition() async {
    try {
      if (!await platform.isLocationServiceEnabled()) {
        return const ServicesOff();
      }
      final position = await platform.getCurrentPosition(
        locationSettings: settings,
      );
      return Located(
        point: GeoPoint(
          latitude: Latitude(position.latitude),
          longitude: Longitude(position.longitude),
        ),
      );
    } on LocationServiceDisabledException {
      return const ServicesOff();
    } on PermissionDeniedException {
      return const AccessRefused();
    } on Exception {
      return const NoFix();
    }
  }

  static LocationAccess _accessOf({required LocationPermission permission}) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationAccess.granted,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.askable,
        LocationPermission.deniedForever => LocationAccess.refused,
      };
}
