import 'dart:async';

sealed class Lookup {
  const Lookup();
}

final class Found extends Lookup {
  const Found({required this.value});

  final String value;
}

final class Missing extends Lookup {
  const Missing();
}

String label({required final Object value}) =>
    value is String? ? 'text' : 'other';

final class Empty extends Stream<int> {
  const Empty();

  @override
  StreamSubscription<int> listen(
    final void Function(int event)? onData, {
    final Function? onError,
    final void Function()? onDone,
    final bool? cancelOnError,
  }) => const Stream<int>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}
