import 'package:na_kernel/na_kernel.dart';

LocalDate aDate({int year = 2026, int month = 9, int day = 10}) =>
    LocalDate(year: year, month: month, day: day);

Instant anInstant({
  int year = 2026,
  int month = 9,
  int day = 10,
  int hour = 12,
  int minute = 0,
}) => Instant(DateTime.utc(year, month, day, hour, minute));

AppVersion aVersion({
  int major = 2,
  int minor = 0,
  int patch = 0,
  int build = 1,
}) => AppVersion(major: major, minor: minor, patch: patch, build: build);
