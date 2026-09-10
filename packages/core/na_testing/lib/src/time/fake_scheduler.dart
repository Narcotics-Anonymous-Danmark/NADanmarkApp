import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/time/test_time.dart';

final class FakeScheduler implements Scheduler {
  const FakeScheduler({required this.time});

  final TestTime time;

  @override
  Cancellation after({
    required Duration delay,
    required void Function() action,
  }) => _HandleCancellation(
    handle: time.schedule(delay: delay, action: action, repeat: Repeat.once),
  );

  @override
  Cancellation periodic({
    required Duration period,
    required void Function() action,
  }) => _HandleCancellation(
    handle: time.schedule(
      delay: period,
      action: action,
      repeat: Repeat.periodic,
    ),
  );

  @override
  Debouncer debounce({required Duration window}) =>
      _FakeDebouncer(time: time, window: window);
}

final class _HandleCancellation implements Cancellation {
  const _HandleCancellation({required this.handle});

  final ScheduledHandle handle;

  @override
  void cancel() => handle.cancel();
}

final class _FakeDebouncer implements Debouncer {
  _FakeDebouncer({required this.time, required this.window});

  final TestTime time;
  final Duration window;
  _PendingHandle _pending = const _NoHandle();

  @override
  void call({required void Function() action}) {
    _cancelPending();
    _pending = _Handle(
      handle: time.schedule(delay: window, action: action, repeat: Repeat.once),
    );
  }

  @override
  void dispose() {
    _cancelPending();
    _pending = const _NoHandle();
  }

  void _cancelPending() => switch (_pending) {
    _Handle(:final handle) => handle.cancel(),
    _NoHandle() => null,
  };
}

sealed class _PendingHandle {
  const _PendingHandle();
}

final class _Handle extends _PendingHandle {
  const _Handle({required this.handle});

  final ScheduledHandle handle;
}

final class _NoHandle extends _PendingHandle {
  const _NoHandle();
}
