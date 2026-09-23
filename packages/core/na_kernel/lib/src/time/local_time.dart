import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/hour_of_day.dart';

@immutable
final class LocalTime {
  const LocalTime({required this.hour, required this.minute});

  final HourOfDay hour;
  final MinuteOfHour minute;

  int get minutesSinceMidnight => hour.value * 60 + minute.value;

  LocalTime plus({required Duration duration}) {
    final total =
        (minutesSinceMidnight + duration.inMinutes) % Duration.minutesPerDay;
    return LocalTime(
      hour: HourOfDay(total ~/ 60),
      minute: MinuteOfHour(total % 60),
    );
  }

  String get hhmm =>
      '${hour.value.toString().padLeft(2, '0')}:'
      '${minute.value.toString().padLeft(2, '0')}';

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  String toString() => hhmm;
}
