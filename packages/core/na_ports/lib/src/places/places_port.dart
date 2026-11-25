import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class PlacesPort {
  Future<Outcome<List<PlacePrediction>, Failure>> predictions({
    required PlaceQuery query,
    required Language language,
  });

  Future<Outcome<GeoPoint, Failure>> locate({required PlaceId place});
}

final Provider<PlacesPort> placesPortProvider = unboundPort(
  portName: 'PlacesPort',
);
