import 'package:meta/meta.dart';
import 'package:na_kernel/src/jft/danish_month.dart';
import 'package:na_kernel/src/jft/jft_entry.dart';
import 'package:na_kernel/src/time/local_date.dart';

@immutable
sealed class JftLookup {
  const JftLookup();
}

final class JftFound extends JftLookup {
  const JftFound({required this.entry});

  final JftEntry entry;

  @override
  int get hashCode => Object.hash(JftFound, entry);

  @override
  bool operator ==(Object other) => other is JftFound && other.entry == entry;
}

final class JftMissing extends JftLookup {
  const JftMissing({required this.date});

  final LocalDate date;

  @override
  int get hashCode => Object.hash(JftMissing, date);

  @override
  bool operator ==(Object other) => other is JftMissing && other.date == date;
}

@immutable
final class JftCalendar {
  const JftCalendar({required this.entries});

  static const int expectedEntryCount = 366;

  final List<JftEntry> entries;

  JftLookup entryFor({required LocalDate date}) {
    final month = DanishMonth.ofNumber(number: date.month);
    final matches = entries.where(
      (entry) => entry.day == date.day && entry.month == month,
    );
    return matches.isEmpty
        ? JftMissing(date: date)
        : JftFound(entry: matches.first);
  }

  List<String> get missingDays => List.unmodifiable(
    DanishMonth.values.expand(
      (month) => List.generate(month.daysInLeapYear, (index) => index + 1)
          .where(
            (day) =>
                entries
                    .where((entry) => entry.day == day && entry.month == month)
                    .length !=
                1,
          )
          .map((day) => '$day. ${month.name}'),
    ),
  );
}
