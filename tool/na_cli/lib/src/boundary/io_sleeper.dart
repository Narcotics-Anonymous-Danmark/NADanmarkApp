import 'package:na_cli/src/ports/sleeper.dart';

final class IoSleeper implements Sleeper {
  const IoSleeper();

  @override
  Future<void> sleep({required final Duration duration}) =>
      Future<void>.delayed(duration);
}
