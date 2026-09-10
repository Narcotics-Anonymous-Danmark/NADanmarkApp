import 'package:na_kernel/na_kernel.dart';

final class RecordingEventBus implements EventBus {
  RecordingEventBus() : _inner = BroadcastEventBus();

  final BroadcastEventBus _inner;
  final List<DomainEvent> recorded = [];

  @override
  void publish({required DomainEvent event}) {
    recorded.add(event);
    _inner.publish(event: event);
  }

  @override
  Stream<T> on<T extends DomainEvent>() => _inner.on<T>();

  @override
  Stream<DomainEvent> get all => _inner.all;

  List<T> recordedOf<T extends DomainEvent>() =>
      List.unmodifiable(recorded.whereType<T>());

  Future<void> dispose() => _inner.dispose();
}
