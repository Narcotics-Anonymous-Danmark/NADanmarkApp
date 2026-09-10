import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class JftPort {
  Future<Outcome<JftCalendar, Failure>> load();
}

final Provider<JftPort> jftPortProvider = unboundPort(portName: 'JftPort');
