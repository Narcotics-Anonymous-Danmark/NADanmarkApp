import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

final Provider<Clock> clockProvider = unboundPort(portName: 'Clock');

final Provider<Ticker> tickerProvider = unboundPort(portName: 'Ticker');

final Provider<Scheduler> schedulerProvider = unboundPort(
  portName: 'Scheduler',
);
