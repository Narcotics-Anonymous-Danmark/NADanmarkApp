import 'package:adapter_clock/src/dart_scheduler.dart';
import 'package:adapter_clock/src/dart_ticker.dart';
import 'package:adapter_clock/src/system_clock.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> clockOverrides({required TimeZoneId zone}) {
  final clock = SystemClock(zoneName: zone);
  return [
    clockProvider.overrideWithValue(clock),
    tickerProvider.overrideWithValue(DartTicker(clock: clock)),
    schedulerProvider.overrideWithValue(const DartScheduler()),
  ];
}
