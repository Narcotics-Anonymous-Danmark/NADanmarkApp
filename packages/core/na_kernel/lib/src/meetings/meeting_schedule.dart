import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/meeting.dart';
import 'package:na_kernel/src/time/hour_of_day.dart';
import 'package:na_kernel/src/time/local_time.dart';
import 'package:na_kernel/src/time/weekday.dart';

@immutable
final class DaySection {
  const DaySection({required this.weekday, required this.meetings});

  final Weekday weekday;
  final List<Meeting> meetings;

  int get count => meetings.length;

  @override
  int get hashCode => Object.hash(weekday, Object.hashAll(meetings));

  @override
  bool operator ==(Object other) =>
      other is DaySection &&
      other.weekday == weekday &&
      const ListEquality<Meeting>().equals(other.meetings, meetings);

  @override
  String toString() => '${weekday.name} ($count)';
}

@immutable
sealed class DayFilter {
  const DayFilter();
}

final class AllDays extends DayFilter {
  const AllDays();

  @override
  int get hashCode => (AllDays).hashCode;

  @override
  bool operator ==(Object other) => other is AllDays;

  @override
  String toString() => 'AllDays';
}

final class OnlyDay extends DayFilter {
  const OnlyDay({required this.weekday});

  final Weekday weekday;

  @override
  int get hashCode => Object.hash(OnlyDay, weekday);

  @override
  bool operator ==(Object other) =>
      other is OnlyDay && other.weekday == weekday;

  @override
  String toString() => 'OnlyDay(${weekday.name})';
}

@immutable
final class HourRange {
  const HourRange({required this.lower, required this.upper});

  static const HourRange wholeDay = HourRange(
    lower: HourOfDay.first,
    upper: HourOfDay.last,
  );

  final HourOfDay lower;
  final HourOfDay upper;

  HourRangeMembership membershipOf({required LocalTime time}) =>
      time.hour.value >= lower.value && time.hour.value <= upper.value
      ? HourRangeMembership.inside
      : HourRangeMembership.outside;

  @override
  int get hashCode => Object.hash(lower, upper);

  @override
  bool operator ==(Object other) =>
      other is HourRange && other.lower == lower && other.upper == upper;

  @override
  String toString() => '${lower.value}-${upper.value}';
}

enum HourRangeMembership { inside, outside }

final class MeetingSchedule {
  const MeetingSchedule();

  List<DaySection> group({
    required List<Meeting> meetings,
    required FirstDayOfWeek firstDay,
  }) => List.unmodifiable(
    Weekday.orderedFrom(firstDay: firstDay)
        .map(
          (weekday) => DaySection(
            weekday: weekday,
            meetings: List.unmodifiable(
              meetings
                  .where((meeting) => meeting.weekday == weekday)
                  .sortedBy<num>(
                    (meeting) => meeting.start.minutesSinceMidnight,
                  ),
            ),
          ),
        )
        .where((section) => section.meetings.isNotEmpty),
  );

  List<Meeting> filter({
    required List<Meeting> meetings,
    required DayFilter day,
    required HourRange hours,
  }) => List.unmodifiable(
    meetings
        .where(
          (meeting) => switch (day) {
            AllDays() => true,
            OnlyDay(:final weekday) => meeting.weekday == weekday,
          },
        )
        .where(
          (meeting) =>
              hours.membershipOf(time: meeting.start) ==
              HourRangeMembership.inside,
        ),
  );
}
