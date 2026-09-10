import 'package:meta/meta.dart';

@immutable
final class LocalTime {
  const LocalTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  LocalTime plus({required Duration duration}) {
    final total =
        (minutesSinceMidnight + duration.inMinutes) % Duration.minutesPerDay;
    return LocalTime(hour: total ~/ 60, minute: total % 60);
  }

  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  String toString() => hhmm;
}
