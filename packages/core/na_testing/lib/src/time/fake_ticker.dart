import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/time/test_time.dart';

final class FakeTicker implements Ticker {
  const FakeTicker({required this.time});

  final TestTime time;

  @override
  Stream<Instant> every({required Duration period}) {
    late final StreamController<Instant> controller;
    late final ScheduledHandle handle;
    controller = StreamController<Instant>(
      onListen: () {
        handle = time.schedule(
          delay: period,
          action: () => controller.add(time.now),
          repeat: Repeat.periodic,
        );
      },
      onCancel: () {
        handle.cancel();
        return controller.close();
      },
    );
    return controller.stream;
  }
}
