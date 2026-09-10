import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

final Provider<EventBus> eventBusProvider = unboundPort(portName: 'EventBus');
