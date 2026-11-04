import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/time/test_time.dart';

final class FakeTicker implements Ticker {
  const FakeTicker({required this.time});

  final TestTime time;

  @override
  Stream<Instant> every({required Duration period}) {
    final controller = StreamController<Instant>();
    _Ticks ticks = const _NotListened();
    controller
      ..onListen = () {
        ticks = _Ticking(
          handle: time.schedule(
            delay: period,
            action: () => controller.add(time.now),
            repeat: Repeat.periodic,
          ),
        );
      }
      ..onCancel = () {
        switch (ticks) {
          case _Ticking(:final handle):
            handle.cancel();
          case _NotListened():
            break;
        }
        return controller.close();
      };
    return controller.stream;
  }
}

sealed class _Ticks {
  const _Ticks();
}

final class _NotListened extends _Ticks {
  const _NotListened();
}

final class _Ticking extends _Ticks {
  const _Ticking({required this.handle});

  final ScheduledHandle handle;
}
