import 'dart:async';

import 'package:na_kernel/na_kernel.dart';

final class DartScheduler implements Scheduler {
  const DartScheduler();

  @override
  Cancellation after({
    required Duration delay,
    required void Function() action,
  }) => _TimerCancellation(timer: Timer(delay, action));

  @override
  Cancellation periodic({
    required Duration period,
    required void Function() action,
  }) => _TimerCancellation(timer: Timer.periodic(period, (_) => action()));

  @override
  Debouncer debounce({required Duration window}) =>
      _TimerDebouncer(window: window);
}

final class _TimerCancellation implements Cancellation {
  const _TimerCancellation({required this.timer});

  final Timer timer;

  @override
  void cancel() => timer.cancel();
}

final class _TimerDebouncer implements Debouncer {
  _TimerDebouncer({required this.window});

  final Duration window;
  _Pending _pending = const _Nothing();

  @override
  void call({required void Function() action}) {
    _cancelPending();
    _pending = _Scheduled(timer: Timer(window, action));
  }

  @override
  void dispose() {
    _cancelPending();
    _pending = const _Nothing();
  }

  void _cancelPending() => switch (_pending) {
    _Scheduled(:final timer) => timer.cancel(),
    _Nothing() => null,
  };
}

sealed class _Pending {
  const _Pending();
}

final class _Scheduled extends _Pending {
  const _Scheduled({required this.timer});

  final Timer timer;
}

final class _Nothing extends _Pending {
  const _Nothing();
}
