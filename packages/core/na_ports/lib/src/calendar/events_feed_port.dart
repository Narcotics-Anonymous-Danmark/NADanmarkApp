import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class EventsFeedPort {
  Future<Outcome<List<CalendarEvent>, Failure>> events({
    required EventCategory category,
  });
}

final Provider<EventsFeedPort> eventsFeedPortProvider = unboundPort(
  portName: 'EventsFeedPort',
);
