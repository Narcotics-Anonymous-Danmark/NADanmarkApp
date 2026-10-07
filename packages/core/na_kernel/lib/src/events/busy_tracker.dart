import 'package:na_kernel/src/events/domain_event.dart';
import 'package:na_kernel/src/events/event_bus.dart';

final class BusyTracker {
  const BusyTracker({required this.bus});

  final EventBus bus;

  Future<T> track<T>({
    required BusyActivity activity,
    required Future<T> Function() work,
  }) async {
    final span = begin(activity: activity);
    try {
      return await work();
    } finally {
      span.end();
    }
  }

  BusySpan begin({required BusyActivity activity}) {
    bus.publish(event: BusyStarted(activity: activity));
    return BusySpan._(bus: bus, activity: activity);
  }
}

enum BusySpanState { open, ended }

final class BusySpan {
  BusySpan._({required this.bus, required this.activity});

  final EventBus bus;
  final BusyActivity activity;
  BusySpanState _state = BusySpanState.open;

  BusySpanState get state => _state;

  void end() {
    switch (_state) {
      case BusySpanState.open:
        _state = BusySpanState.ended;
        bus.publish(event: BusyEnded(activity: activity));
      case BusySpanState.ended:
        break;
    }
  }
}
