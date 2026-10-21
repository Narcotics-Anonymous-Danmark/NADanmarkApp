import 'package:na_kernel/na_kernel.dart';

final class SystemClock implements Clock {
  const SystemClock({required this.zoneName});

  final TimeZoneId zoneName;

  @override
  Instant now() => Instant(DateTime.now().toUtc());

  @override
  LocalDate today() => LocalDate.fromDateTime(dateTime: DateTime.now());

  @override
  LocalTime localTimeNow() {
    final local = DateTime.now();
    return LocalTime(
      hour: HourOfDay(local.hour),
      minute: MinuteOfHour(local.minute),
    );
  }

  @override
  TimeZoneId zone() => zoneName;

  @override
  Instant instantOf({required LocalDate date, required LocalTime time}) =>
      Instant(
        DateTime(
          date.year,
          date.month,
          date.day,
          time.hour.value,
          time.minute.value,
        ).toUtc(),
      );
}
