import 'package:na_kernel/src/events/domain_event.dart';

abstract interface class EventBus {
  void publish({required DomainEvent event});

  Stream<T> on<T extends DomainEvent>();

  Stream<DomainEvent> get all;
}
