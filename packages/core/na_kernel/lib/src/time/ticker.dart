import 'package:na_kernel/src/time/instant.dart';

abstract interface class Ticker {
  Stream<Instant> every({required Duration period});
}
