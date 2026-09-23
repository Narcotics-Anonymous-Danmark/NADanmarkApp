import 'package:feature_meetings/src/application/meeting_list_controller.dart';
import 'package:feature_meetings/src/widgets/meeting_card.dart';
import 'package:feature_meetings/src/widgets/meeting_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class MeetingList extends ConsumerWidget {
  const MeetingList({
    required this.listKey,
    required this.meetings,
    required this.firstDay,
    super.key,
  });

  final MeetingListKey listKey;
  final List<Meeting> meetings;
  final FirstDayOfWeek firstDay;

  static const MeetingSchedule _schedule = MeetingSchedule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(meetingListProvider(listKey));
    final sections = _schedule.group(
      meetings: _schedule.filter(
        meetings: meetings,
        day: view.day,
        hours: view.hours,
      ),
      firstDay: firstDay,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeetingFilterBar(listKey: listKey, view: view, firstDay: firstDay),
        if (sections.isEmpty)
          const NothingFound()
        else
          ...sections.map(
            (section) => DaySectionView(
              listKey: listKey,
              section: section,
              expansion: view.expansionOf(weekday: section.weekday),
            ),
          ),
      ],
    );
  }
}

final class MeetingFilterBar extends ConsumerWidget {
  const MeetingFilterBar({
    required this.listKey,
    required this.view,
    required this.firstDay,
    super.key,
  });

  final MeetingListKey listKey;
  final MeetingListView view;
  final FirstDayOfWeek firstDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(meetingListProvider(listKey).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaListRow(
          key: const Key('meeting-day-filter'),
          label: l10n.meetingDayFilter,
          value: l10n.dayFilterName(day: view.day),
          onTap: () async {
            final choice = await showNaOptionDialog<DayFilter>(
              context: context,
              title: l10n.meetingDayFilter,
              options:
                  [
                        const AllDays(),
                        ...Weekday.orderedFrom(
                          firstDay: firstDay,
                        ).map((weekday) => OnlyDay(weekday: weekday)),
                      ]
                      .map(
                        (day) => NaOption(
                          value: day,
                          label: l10n.dayFilterName(day: day),
                        ),
                      )
                      .toList(growable: false),
              selected: view.day,
              cancelLabel: l10n.cancel,
            );
            switch (choice) {
              case NaOptionPicked(:final value):
                controller.selectDay(day: value);
              case NaOptionCancelled():
                return;
            }
          },
        ),
        HourRangeRow(
          hours: view.draftHours,
          onChanged: (hours) => controller.dragHours(hours: hours),
        ),
      ],
    );
  }
}

final class HourRangeRow extends StatelessWidget {
  const HourRangeRow({required this.hours, required this.onChanged, super.key});

  final HourRange hours;
  final ValueChanged<HourRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(bottom: BorderSide(color: theme.colors.background)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Row(
          children: [
            Icon(NaIcons.clock, size: 20, color: theme.colors.inkMuted),
            const SizedBox(width: Space.sm),
            Expanded(
              child: NaRangeSlider(
                key: const Key('meeting-hour-range'),
                values: NaRangeValues(
                  lower: hours.lower.value,
                  upper: hours.upper.value,
                ),
                min: HourOfDay.first.value,
                max: HourOfDay.last.value,
                lowerLabel: l10n.hourRangeLower,
                upperLabel: l10n.hourRangeUpper,
                onChanged: (values) => onChanged(
                  HourRange(
                    lower: HourOfDay(values.lower),
                    upper: HourOfDay(values.upper),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            Icon(NaIcons.clock, size: 20, color: theme.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

final class DaySectionView extends ConsumerWidget {
  const DaySectionView({
    required this.listKey,
    required this.section,
    required this.expansion,
    super.key,
  });

  final MeetingListKey listKey;
  final DaySection section;
  final SectionExpansion expansion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaSectionHeader(
          key: Key('meeting-section-${section.weekday.name}'),
          label: l10n.meetingDayCount(
            l10n.weekdayName(weekday: section.weekday),
            section.count,
          ),
          tone: section.weekday == today
              ? NaSectionTone.highlighted
              : NaSectionTone.normal,
          expansion: switch (expansion) {
            SectionExpansion.expanded => NaExpansion.expanded,
            SectionExpansion.collapsed => NaExpansion.collapsed,
          },
          onTap: () => ref
              .read(meetingListProvider(listKey).notifier)
              .toggle(weekday: section.weekday),
        ),
        ...switch (expansion) {
          SectionExpansion.expanded => section.meetings.map(
            (meeting) => MeetingCard(meeting: meeting),
          ),
          SectionExpansion.collapsed => const <Widget>[],
        },
      ],
    );
  }
}

final class NothingFound extends StatelessWidget {
  const NothingFound({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('meetings-nothing-found'),
    padding: const EdgeInsets.all(Space.lg),
    child: Text(
      AppLocalizations.of(context).nothingFound,
      textAlign: TextAlign.center,
      style: NaTheme.of(context).typography.body,
    ),
  );
}
