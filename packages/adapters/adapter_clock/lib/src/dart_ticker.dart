import 'package:na_kernel/na_kernel.dart';

final class DartTicker implements Ticker {
  const DartTicker({required this.clock});

  final Clock clock;

  @override
  Stream<Instant> every({required Duration period}) =>
      Stream<void>.periodic(period).map((_) => clock.now());
}
