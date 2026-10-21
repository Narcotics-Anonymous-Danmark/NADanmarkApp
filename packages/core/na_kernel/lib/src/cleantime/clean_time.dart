import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/time/local_date.dart';

extension type const YearCount(int value) {
  List<YearCount> through({required YearCount last}) => List.unmodifiable(
    List.generate(
      last.value < value ? 0 : last.value - value + 1,
      (offset) => YearCount(value + offset),
    ),
  );
}

extension type const MonthCount(int value) {}

extension type const DayCount(int value) {}

@immutable
final class YearsMonthsDays {
  const YearsMonthsDays({
    required this.years,
    required this.months,
    required this.days,
  });

  final YearCount years;
  final MonthCount months;
  final DayCount days;

  @override
  int get hashCode => Object.hash(years, months, days);

  @override
  bool operator ==(Object other) =>
      other is YearsMonthsDays &&
      other.years == years &&
      other.months == months &&
      other.days == days;

  @override
  String toString() =>
      'YearsMonthsDays(${years.value}, ${months.value}, ${days.value})';
}

@immutable
final class MonthsDays {
  const MonthsDays({required this.months, required this.days});

  final MonthCount months;
  final DayCount days;

  @override
  int get hashCode => Object.hash(months, days);

  @override
  bool operator ==(Object other) =>
      other is MonthsDays && other.months == months && other.days == days;

  @override
  String toString() => 'MonthsDays(${months.value}, ${days.value})';
}

@immutable
final class CleanTime {
  const CleanTime({
    required this.yearsMonthsDays,
    required this.monthsDays,
    required this.days,
  });

  factory CleanTime.between({
    required LocalDate cleanDate,
    required LocalDate today,
  }) {
    final start = switch (cleanDate.compareTo(other: today)) {
      Comparison.after => today,
      Comparison.before || Comparison.same => cleanDate,
    };
    final years = YearCount(start.wholeYearsUntil(other: today));
    final afterYears = start.plusYears(years: years.value);
    final months = MonthCount(afterYears.wholeMonthsUntil(other: today));
    final allMonths = MonthCount(start.wholeMonthsUntil(other: today));
    return CleanTime(
      yearsMonthsDays: YearsMonthsDays(
        years: years,
        months: months,
        days: DayCount(
          afterYears.plusMonths(months: months.value).daysUntil(other: today),
        ),
      ),
      monthsDays: MonthsDays(
        months: allMonths,
        days: DayCount(
          start.plusMonths(months: allMonths.value).daysUntil(other: today),
        ),
      ),
      days: DayCount(start.daysUntil(other: today)),
    );
  }

  final YearsMonthsDays yearsMonthsDays;
  final MonthsDays monthsDays;
  final DayCount days;

  @override
  int get hashCode => Object.hash(yearsMonthsDays, monthsDays, days);

  @override
  bool operator ==(Object other) =>
      other is CleanTime &&
      other.yearsMonthsDays == yearsMonthsDays &&
      other.monthsDays == monthsDays &&
      other.days == days;

  @override
  String toString() =>
      'CleanTime($yearsMonthsDays, $monthsDays, ${days.value})';
}
