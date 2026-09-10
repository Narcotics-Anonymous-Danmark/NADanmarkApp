import 'package:riverpod/riverpod.dart';

final class UnboundPortError extends Error {
  UnboundPortError({required this.portName});

  final String portName;

  @override
  String toString() =>
      '$portName is not bound. Add its adapter override to the '
      'ProviderContainer in the composition root or the test container.';
}

Provider<T> unboundPort<T>({required String portName}) =>
    Provider<T>((ref) => throw UnboundPortError(portName: portName));
