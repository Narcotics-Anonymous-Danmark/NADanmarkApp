import 'package:na_kernel/src/events/domain_event.dart';
import 'package:na_kernel/src/events/event_bus.dart';

final class BusyTracker {
  const BusyTracker({required this.bus});

  final EventBus bus;

  Future<T> track<T>({
    required BusyActivity activity,
    required Future<T> Function() work,
  }) async {
    bus.publish(event: BusyStarted(activity: activity));
    try {
      return await work();
    } finally {
      bus.publish(event: BusyEnded(activity: activity));
    }
  }
}
