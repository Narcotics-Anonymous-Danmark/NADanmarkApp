import 'dart:async';

import 'package:feature_meetings/feature_meetings.dart';
import 'package:feature_meetings_search/src/application/nearby_controller.dart';
import 'package:feature_meetings_search/src/widgets/municipality_bodies.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

const MeetingListKey nearbyListKey = MeetingListKey('nearby');

final class NearbyBody extends ConsumerWidget {
  const NearbyBody({required this.firstDay, super.key});

  final FirstDayOfWeek firstDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaScrollBody(
    children: [
      switch (ref.watch(
        nearbyMeetingsProvider.select((state) => state.results),
      )) {
        AwaitingFirstResult() => const SizedBox.shrink(),
        SearchFailed() => MeetingsLoadFailed(
          onRetry: () => ref.read(nearbyMeetingsProvider.notifier).retry(),
        ),
        Shown(:final meetings, :final origin) => NearbyResultsView(
          meetings: meetings,
          origin: origin,
          firstDay: firstDay,
        ),
      },
    ],
  );
}

final class NearbyResultsView extends StatelessWidget {
  const NearbyResultsView({
    required this.meetings,
    required this.origin,
    required this.firstDay,
    super.key,
  });

  final List<Meeting> meetings;
  final SearchOrigin origin;
  final FirstDayOfWeek firstDay;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      switch (origin) {
        DefaultPosition() => const LocationNotSetNote(),
        DevicePosition() => const SizedBox.shrink(),
      },
      switch (meetings) {
        [] => const NothingFound(),
        [_, ...] => MeetingList(
          listKey: nearbyListKey,
          meetings: meetings,
          firstDay: firstDay,
        ),
      },
    ],
  );
}

final class LocationNotSetNote extends StatelessWidget {
  const LocationNotSetNote({super.key});

  @override
  Widget build(BuildContext context) => NaErrorState(
    key: const Key('nearby-location-not-set'),
    message: AppLocalizations.of(context).noLocation,
  );
}

final class NearbyFooter extends ConsumerWidget {
  const NearbyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    final controller = ref.read(nearbyMeetingsProvider.notifier);
    final radius = ref.watch(
      nearbyMeetingsProvider.select((state) => state.radius),
    );
    return NaFooterBar(
      children: [
        NaButton(
          key: const Key('nearby-locate'),
          label: l10n.locationsearch,
          onPressed: () => unawaited(controller.locate()),
        ),
        Text(
          l10n.nearbyRadiusValue(radius.value),
          key: const Key('nearby-radius-value'),
          style: theme.typography.body.copyWith(color: theme.colors.primary),
        ),
        NaSliderWithEnds(
          sliderKey: const Key('nearby-radius-slider'),
          value: SliderValue(radius.value),
          min: SliderValue(Km.searchRadiusMinimum.value),
          max: SliderValue(Km.searchRadiusMaximum.value),
          label: NaLabel(l10n.nearbyRadiusLabel),
          minLabel: NaLabel(l10n.kmValue(Km.searchRadiusMinimum.value)),
          maxLabel: NaLabel(l10n.kmValue(Km.searchRadiusMaximum.value)),
          onChanged: (value) =>
              controller.changeRadius(radius: Km(value.value)),
          onChangeEnd: (value) {},
        ),
      ],
    );
  }
}
