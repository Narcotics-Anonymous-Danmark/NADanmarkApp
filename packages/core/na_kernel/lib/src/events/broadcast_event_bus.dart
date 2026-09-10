import 'dart:async';

import 'package:na_kernel/src/events/domain_event.dart';
import 'package:na_kernel/src/events/event_bus.dart';

final class BroadcastEventBus implements EventBus {
  BroadcastEventBus() : _controller = StreamController<DomainEvent>.broadcast();

  final StreamController<DomainEvent> _controller;

  @override
  void publish({required DomainEvent event}) => _controller.add(event);

  @override
  Stream<T> on<T extends DomainEvent>() => _controller.stream.whereType<T>();

  @override
  Stream<DomainEvent> get all => _controller.stream;

  Future<void> dispose() => _controller.close();
}

extension _WhereType<S> on Stream<S> {
  Stream<T> whereType<T>() =>
      where((event) => event is T).map((event) => event as T);
}
