import 'package:feature_meetings/feature_meetings.dart';
import 'package:feature_meetings_search/src/application/municipality_controllers.dart';
import 'package:feature_meetings_search/src/application/municipality_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class MunicipalityListBody extends ConsumerWidget {
  const MunicipalityListBody({required this.onOpen, super.key});

  final ValueChanged<MunicipalitySegment> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return NaScrollBody(
      children: [
        switch (ref.watch(municipalitiesProvider)) {
          Loading() => const SizedBox.shrink(),
          Failed() => MeetingsLoadFailed(
            onRetry: () => ref.read(municipalitiesProvider.notifier).retry(),
          ),
          Loaded(value: final municipalities) when municipalities.isEmpty =>
            const NothingFound(),
          Loaded(value: final municipalities) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: municipalities
                .map((municipality) {
                  final label = l10n.municipalityName(
                    municipality: municipality,
                  );
                  return NaDisclosureRow(
                    key: Key('municipality-row-$label'),
                    label: label,
                    onTap: () => onOpen(
                      MunicipalitySegment.of(municipality: municipality),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        },
      ],
    );
  }
}

final class MunicipalityMeetingsBody extends ConsumerWidget {
  const MunicipalityMeetingsBody({
    required this.municipality,
    required this.firstDay,
    super.key,
  });

  final Municipality municipality;
  final FirstDayOfWeek firstDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaScrollBody(
    children: [
      switch (ref.watch(municipalityMeetingsProvider(municipality))) {
        Loading() => const SizedBox.shrink(),
        Failed() => MeetingsLoadFailed(
          onRetry: () => ref
              .read(municipalityMeetingsProvider(municipality).notifier)
              .retry(),
        ),
        Loaded(value: final meetings) when meetings.isEmpty =>
          const NothingFound(),
        Loaded(value: final meetings) => MeetingList(
          listKey: MeetingListKey(
            MunicipalitySegment.of(municipality: municipality).value,
          ),
          meetings: meetings,
          firstDay: firstDay,
        ),
      },
    ],
  );
}

final class MeetingsLoadFailed extends StatelessWidget {
  const MeetingsLoadFailed({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaErrorState(message: l10n.meetingsLoadFailed),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: NaButton(
            key: const Key('meetings-retry'),
            label: l10n.tryAgain,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
