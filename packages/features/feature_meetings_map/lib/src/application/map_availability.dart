import 'package:flutter/widgets.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

typedef MapSurface =
    Widget Function({
      required MapCamera initial,
      required MyLocationLayer myLocation,
      required List<MapMarker> markers,
      required MapEvents events,
    });

sealed class MapAvailability {
  const MapAvailability();
}

final class MapsAvailable extends MapAvailability {
  const MapsAvailable({required this.surface});

  final MapSurface surface;
}

final class MapsUnavailable extends MapAvailability {
  const MapsUnavailable();
}

final Provider<MapAvailability> mapAvailabilityProvider = unboundPort(
  portName: 'MapAvailability',
);
