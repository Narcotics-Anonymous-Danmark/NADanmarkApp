import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/time/weekday.dart';

@immutable
final class LocalDate {
  const LocalDate({required this.year, required this.month, required this.day});

  factory LocalDate.fromDateTime({required DateTime dateTime}) => LocalDate(
    year: dateTime.year,
    month: dateTime.month,
    day: dateTime.day,
  );

  final int year;
  final int month;
  final int day;

  DateTime get atMidnightUtc => DateTime.utc(year, month, day);

  Weekday get weekday =>
      Weekday.fromIsoNumber(isoNumber: atMidnightUtc.weekday);

  int get dayOfYear => atMidnightUtc.difference(DateTime.utc(year)).inDays + 1;

  int daysUntil({required LocalDate other}) =>
      other.atMidnightUtc.difference(atMidnightUtc).inDays;

  LocalDate plusDays({required int days}) => LocalDate.fromDateTime(
    dateTime: atMidnightUtc.add(Duration(days: days)),
  );

  LocalDate plusMonths({required int months}) {
    final totalMonths = year * 12 + (month - 1) + months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = totalMonths % 12 + 1;
    final lastDay = _daysInMonth(year: targetYear, month: targetMonth);
    return LocalDate(
      year: targetYear,
      month: targetMonth,
      day: day < lastDay ? day : lastDay,
    );
  }

  LocalDate plusYears({required int years}) => plusMonths(months: years * 12);

  int wholeMonthsUntil({required LocalDate other}) {
    final candidate = (other.year - year) * 12 + (other.month - month);
    return switch (plusMonths(months: candidate).compareTo(other: other)) {
      Comparison.after => candidate - 1,
      Comparison.same || Comparison.before => candidate,
    };
  }

  int wholeYearsUntil({required LocalDate other}) =>
      wholeMonthsUntil(other: other) ~/ 12;

  Comparison compareTo({required LocalDate other}) =>
      switch (atMidnightUtc.compareTo(other.atMidnightUtc)) {
        < 0 => Comparison.before,
        0 => Comparison.same,
        _ => Comparison.after,
      };

  String get iso8601 =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  String toString() => iso8601;

  static int _daysInMonth({required int year, required int month}) =>
      DateTime.utc(year, month + 1, 0).day;
}
