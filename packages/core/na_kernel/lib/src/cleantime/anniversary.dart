import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/cleantime/clean_time.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/time/local_date.dart';

extension type const KeyTagName(String file) {}

enum AnniversaryKind {
  oneDay(keyTag: KeyTagName('1-day')),
  thirtyDays(keyTag: KeyTagName('30-days')),
  sixtyDays(keyTag: KeyTagName('60-days')),
  ninetyDays(keyTag: KeyTagName('90-days')),
  sixMonths(keyTag: KeyTagName('6-months')),
  nineMonths(keyTag: KeyTagName('9-months')),
  oneYear(keyTag: KeyTagName('1-year')),
  eighteenMonths(keyTag: KeyTagName('18-months')),
  years(keyTag: KeyTagName('x-years'))
  ;

  const AnniversaryKind({required this.keyTag});

  final KeyTagName keyTag;
}

@immutable
sealed class AnniversaryOffset {
  const AnniversaryOffset();

  LocalDate from({required LocalDate cleanDate});
}

final class AfterDays extends AnniversaryOffset {
  const AfterDays({required this.days});

  final DayCount days;

  @override
  LocalDate from({required LocalDate cleanDate}) =>
      cleanDate.plusDays(days: days.value);

  @override
  int get hashCode => Object.hash(AfterDays, days);

  @override
  bool operator ==(Object other) => other is AfterDays && other.days == days;

  @override
  String toString() => '${days.value} days';
}

final class AfterMonths extends AnniversaryOffset {
  const AfterMonths({required this.months});

  final MonthCount months;

  @override
  LocalDate from({required LocalDate cleanDate}) =>
      cleanDate.plusMonths(months: months.value);

  @override
  int get hashCode => Object.hash(AfterMonths, months);

  @override
  bool operator ==(Object other) =>
      other is AfterMonths && other.months == months;

  @override
  String toString() => '${months.value} months';
}

final class AfterYears extends AnniversaryOffset {
  const AfterYears({required this.years});

  final YearCount years;

  @override
  LocalDate from({required LocalDate cleanDate}) =>
      cleanDate.plusYears(years: years.value);

  @override
  int get hashCode => Object.hash(AfterYears, years);

  @override
  bool operator ==(Object other) => other is AfterYears && other.years == years;

  @override
  String toString() => '${years.value} years';
}

@immutable
final class Anniversary {
  const Anniversary({required this.kind, required this.offset});

  factory Anniversary.afterYears({required YearCount years}) => Anniversary(
    kind: AnniversaryKind.years,
    offset: AfterYears(years: years),
  );

  static const List<Anniversary> fixed = [
    Anniversary(
      kind: AnniversaryKind.oneDay,
      offset: AfterDays(days: DayCount(1)),
    ),
    Anniversary(
      kind: AnniversaryKind.thirtyDays,
      offset: AfterDays(days: DayCount(30)),
    ),
    Anniversary(
      kind: AnniversaryKind.sixtyDays,
      offset: AfterDays(days: DayCount(60)),
    ),
    Anniversary(
      kind: AnniversaryKind.ninetyDays,
      offset: AfterDays(days: DayCount(90)),
    ),
    Anniversary(
      kind: AnniversaryKind.sixMonths,
      offset: AfterMonths(months: MonthCount(6)),
    ),
    Anniversary(
      kind: AnniversaryKind.nineMonths,
      offset: AfterMonths(months: MonthCount(9)),
    ),
    Anniversary(
      kind: AnniversaryKind.oneYear,
      offset: AfterYears(years: YearCount(1)),
    ),
    Anniversary(
      kind: AnniversaryKind.eighteenMonths,
      offset: AfterMonths(months: MonthCount(18)),
    ),
  ];

  static const YearCount firstMultiYear = YearCount(2);

  static const YearCount upcomingWindow = YearCount(2);

  final AnniversaryKind kind;
  final AnniversaryOffset offset;

  LocalDate dateFor({required LocalDate cleanDate}) =>
      offset.from(cleanDate: cleanDate);

  @override
  int get hashCode => Object.hash(kind, offset);

  @override
  bool operator ==(Object other) =>
      other is Anniversary && other.kind == kind && other.offset == offset;

  @override
  String toString() => 'Anniversary(${kind.name}, $offset)';
}

@immutable
sealed class AnniversaryToday {
  const AnniversaryToday();

  factory AnniversaryToday.of({
    required LocalDate cleanDate,
    required LocalDate today,
  }) {
    final years = YearCount(cleanDate.wholeYearsUntil(other: today));
    final candidates = [
      ...Anniversary.fixed,
      if (years.value >= Anniversary.firstMultiYear.value)
        Anniversary.afterYears(years: years),
    ];
    return switch (candidates.firstWhereOrNull(
      (anniversary) => anniversary.dateFor(cleanDate: cleanDate) == today,
    )) {
      final Anniversary anniversary => OnAnniversary(anniversary: anniversary),
      null => const NoAnniversary(),
    };
  }
}

final class OnAnniversary extends AnniversaryToday {
  const OnAnniversary({required this.anniversary});

  final Anniversary anniversary;

  @override
  int get hashCode => anniversary.hashCode;

  @override
  bool operator ==(Object other) =>
      other is OnAnniversary && other.anniversary == anniversary;

  @override
  String toString() => 'OnAnniversary($anniversary)';
}

final class NoAnniversary extends AnniversaryToday {
  const NoAnniversary();

  @override
  int get hashCode => (NoAnniversary).hashCode;

  @override
  bool operator ==(Object other) => other is NoAnniversary;

  @override
  String toString() => 'NoAnniversary()';
}

@immutable
final class UpcomingAnniversary {
  const UpcomingAnniversary({required this.anniversary, required this.date});

  final Anniversary anniversary;
  final LocalDate date;

  static List<UpcomingAnniversary> within({
    required LocalDate cleanDate,
    required LocalDate today,
  }) {
    final last = today.plusYears(years: Anniversary.upcomingWindow.value);
    final multiYears = Anniversary.firstMultiYear
        .through(last: YearCount(cleanDate.wholeYearsUntil(other: last)))
        .map((years) => Anniversary.afterYears(years: years));
    return List.unmodifiable(
      [...Anniversary.fixed, ...multiYears]
          .map(
            (anniversary) => UpcomingAnniversary(
              anniversary: anniversary,
              date: anniversary.dateFor(cleanDate: cleanDate),
            ),
          )
          .where(
            (upcoming) =>
                upcoming.date.compareTo(other: today) != Comparison.before &&
                upcoming.date.compareTo(other: last) != Comparison.after,
          ),
    );
  }

  @override
  int get hashCode => Object.hash(anniversary, date);

  @override
  bool operator ==(Object other) =>
      other is UpcomingAnniversary &&
      other.anniversary == anniversary &&
      other.date == date;

  @override
  String toString() => 'UpcomingAnniversary($anniversary, $date)';
}
