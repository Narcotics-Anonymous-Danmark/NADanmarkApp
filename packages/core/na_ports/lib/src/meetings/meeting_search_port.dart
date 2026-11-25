import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class MeetingSearchPort {
  Future<Outcome<List<Meeting>, Failure>> denmarkMeetings();

  Future<Outcome<List<MunicipalityName>, Failure>> denmarkMunicipalities();

  Future<Outcome<List<Meeting>, Failure>> nearbyMeetings({
    required GeoPoint centre,
    required Km radius,
  });

  Future<Outcome<List<MeetingSpot>, Failure>> meetingSpots({
    required GeoPoint centre,
    required MapRadius radius,
  });

  Future<Outcome<List<Meeting>, Failure>> meetingsById({
    required List<MeetingId> ids,
  });
}

final Provider<MeetingSearchPort> meetingSearchPortProvider = unboundPort(
  portName: 'MeetingSearchPort',
);
