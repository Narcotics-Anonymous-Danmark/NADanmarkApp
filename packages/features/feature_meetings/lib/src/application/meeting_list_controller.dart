import 'dart:async';

import 'package:feature_meetings/src/application/meeting_formats_controller.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

extension type const MeetingListKey(String value) {}

@immutable
sealed class OpenSection {
  const OpenSection();
}

final class NoSectionOpen extends OpenSection {
  const NoSectionOpen();

  @override
  int get hashCode => (NoSectionOpen).hashCode;

  @override
  bool operator ==(Object other) => other is NoSectionOpen;
}

final class SectionOpen extends OpenSection {
  const SectionOpen({required this.weekday});

  final Weekday weekday;

  @override
  int get hashCode => Object.hash(SectionOpen, weekday);

  @override
  bool operator ==(Object other) =>
      other is SectionOpen && other.weekday == weekday;
}

enum SectionExpansion { expanded, collapsed }

@immutable
final class MeetingListView {
  const MeetingListView({
    required this.day,
    required this.hours,
    required this.draftHours,
    required this.open,
  });

  static const MeetingListView initial = MeetingListView(
    day: AllDays(),
    hours: HourRange.wholeDay,
    draftHours: HourRange.wholeDay,
    open: NoSectionOpen(),
  );

  static const Duration hourFilterDelay = Duration(milliseconds: 350);

  final DayFilter day;
  final HourRange hours;
  final HourRange draftHours;
  final OpenSection open;

  SectionExpansion expansionOf({required Weekday weekday}) => switch (open) {
    SectionOpen(weekday: final opened) when opened == weekday =>
      SectionExpansion.expanded,
    SectionOpen() || NoSectionOpen() => SectionExpansion.collapsed,
  };

  MeetingListView withDay({required DayFilter day}) => MeetingListView(
    day: day,
    hours: hours,
    draftHours: draftHours,
    open: open,
  );

  MeetingListView withDraftHours({required HourRange draftHours}) =>
      MeetingListView(
        day: day,
        hours: hours,
        draftHours: draftHours,
        open: open,
      );

  MeetingListView withAppliedHours({required HourRange hours}) =>
      MeetingListView(day: day, hours: hours, draftHours: hours, open: open);

  MeetingListView withOpen({required OpenSection open}) => MeetingListView(
    day: day,
    hours: hours,
    draftHours: draftHours,
    open: open,
  );

  @override
  int get hashCode => Object.hash(day, hours, draftHours, open);

  @override
  bool operator ==(Object other) =>
      other is MeetingListView &&
      other.day == day &&
      other.hours == hours &&
      other.draftHours == draftHours &&
      other.open == open;
}

final NotifierProviderFamily<
  MeetingListController,
  MeetingListView,
  MeetingListKey
>
meetingListProvider = NotifierProvider.autoDispose.family(
  MeetingListController.new,
);

final Provider<Weekday> todayProvider = Provider(
  (ref) => ref.watch(clockProvider).today().weekday,
);

final class MeetingListController extends Notifier<MeetingListView> {
  MeetingListController(this.key);

  final MeetingListKey key;

  late Debouncer _hourFilter;

  @override
  MeetingListView build() {
    _hourFilter = ref
        .read(schedulerProvider)
        .debounce(window: MeetingListView.hourFilterDelay);
    ref.onDispose(_hourFilter.dispose);
    unawaited(ref.read(meetingFormatsProvider.notifier).ensureLoaded());
    return MeetingListView.initial;
  }

  void selectDay({required DayFilter day}) => state = state.withDay(day: day);

  void dragHours({required HourRange hours}) {
    state = state.withDraftHours(draftHours: hours);
    _hourFilter(action: () => state = state.withAppliedHours(hours: hours));
  }

  void toggle({required Weekday weekday}) => state = state.withOpen(
    open: switch (state.expansionOf(weekday: weekday)) {
      SectionExpansion.expanded => const NoSectionOpen(),
      SectionExpansion.collapsed => SectionOpen(weekday: weekday),
    },
  );
}
