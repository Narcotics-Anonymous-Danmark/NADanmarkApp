import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/time/test_time.dart';

final class FakeClock implements Clock {
  const FakeClock({required this.time});

  final TestTime time;

  @override
  Instant now() => time.now;

  @override
  LocalDate today() => LocalDate.fromDateTime(dateTime: time.localDateTime);

  @override
  LocalTime localTimeNow() {
    final local = time.localDateTime;
    return LocalTime(
      hour: HourOfDay(local.hour),
      minute: MinuteOfHour(local.minute),
    );
  }

  @override
  TimeZoneId zone() => time.zone;
}
