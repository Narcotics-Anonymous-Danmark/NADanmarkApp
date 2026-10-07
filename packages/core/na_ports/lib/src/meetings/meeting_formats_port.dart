import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class MeetingFormatsPort {
  Future<Outcome<List<FormatRow>, Failure>> formatRows();
}

final Provider<MeetingFormatsPort> meetingFormatsPortProvider = unboundPort(
  portName: 'MeetingFormatsPort',
);
