import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class GeolocationPort {
  Future<LocationAccess> access();

  Future<LocationAccess> requestAccess();

  Future<PositionFix> currentPosition();
}

final Provider<GeolocationPort> geolocationPortProvider = unboundPort(
  portName: 'GeolocationPort',
);
