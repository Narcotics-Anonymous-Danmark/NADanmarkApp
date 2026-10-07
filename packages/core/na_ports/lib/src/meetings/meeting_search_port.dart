import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class MeetingSearchPort {
  Future<Outcome<List<Meeting>, Failure>> denmarkMeetings();

  Future<Outcome<List<MunicipalityName>, Failure>> denmarkMunicipalities();
}

final Provider<MeetingSearchPort> meetingSearchPortProvider = unboundPort(
  portName: 'MeetingSearchPort',
);
