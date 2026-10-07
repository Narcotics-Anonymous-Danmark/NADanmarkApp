import 'package:adapter_geolocation/src/geolocator_location.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> geolocationOverrides({required GeolocatorPlatform platform}) => [
  geolocationPortProvider.overrideWithValue(
    GeolocatorLocation(platform: platform),
  ),
];
