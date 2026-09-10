import 'package:na_cli/src/ports/clock.dart';

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
