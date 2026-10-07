import 'package:na_kernel/na_kernel.dart';

LocalDate aLocalDate({int year = 2026, int month = 9, int day = 10}) =>
    LocalDate(year: year, month: month, day: day);

LocalTime aLocalTime({int hour = 19, int minute = 0}) =>
    LocalTime(hour: HourOfDay(hour), minute: MinuteOfHour(minute));

Instant anInstant({
  int year = 2026,
  int month = 9,
  int day = 10,
  int hour = 12,
  int minute = 0,
  int second = 0,
}) => Instant(DateTime.utc(year, month, day, hour, minute, second));

AppVersion anAppVersion({
  int major = 2,
  int minor = 0,
  int patch = 0,
  int build = 1,
}) => AppVersion(major: major, minor: minor, patch: patch, build: build);
