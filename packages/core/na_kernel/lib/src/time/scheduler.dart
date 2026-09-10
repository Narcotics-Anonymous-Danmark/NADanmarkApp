abstract interface class Scheduler {
  Cancellation after({
    required Duration delay,
    required void Function() action,
  });

  Cancellation periodic({
    required Duration period,
    required void Function() action,
  });

  Debouncer debounce({required Duration window});
}

abstract interface class Cancellation {
  void cancel();
}

abstract interface class Debouncer {
  void call({required void Function() action});

  void dispose();
}
