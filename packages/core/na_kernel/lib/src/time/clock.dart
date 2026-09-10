import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/time/local_date.dart';
import 'package:na_kernel/src/time/local_time.dart';
import 'package:na_kernel/src/time/time_zone_id.dart';

abstract interface class Clock {
  Instant now();

  LocalDate today();

  LocalTime localTimeNow();

  TimeZoneId zone();
}
