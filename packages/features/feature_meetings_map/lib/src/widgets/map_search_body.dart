import 'dart:async';

import 'package:feature_meetings/feature_meetings.dart';
import 'package:feature_meetings_map/src/application/map_availability.dart';
import 'package:feature_meetings_map/src/application/map_search_controller.dart';
import 'package:feature_meetings_map/src/application/place_search_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class MapSearchBody extends ConsumerWidget {
  const MapSearchBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(mapAvailabilityProvider)) {
        MapsAvailable(:final surface) => MapSearchView(surface: surface),
        MapsUnavailable() => const MapUnavailable(),
      };
}

final class MapUnavailable extends StatelessWidget {
  const MapUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.md),
    child: Align(
      alignment: Alignment.topCenter,
      child: NaErrorState(
        key: const Key('map-unavailable'),
        message: AppLocalizations.of(context).mapUnavailable,
      ),
    ),
  );
}

final class MapSearchView extends ConsumerWidget {
  const MapSearchView({required this.surface, super.key});

  final MapSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(mapSearchProvider.select((state) => state.details), (
      previous,
      next,
    ) {
      switch (next) {
        case DetailsFor(:final meetings):
          unawaited(showMeetingDetails(context: context, meetings: meetings));
        case NoDetails():
          break;
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceSearchBar(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MapCanvas(surface: surface),
              const MapSearchFailure(),
              const PlaceSuggestionList(),
            ],
          ),
        ),
      ],
    );
  }
}

final class MapCanvas extends ConsumerWidget {
  const MapCanvas({required this.surface, super.key});

  final MapSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(mapSearchProvider.select((state) => state.stage));
    return switch (stage) {
      PlacingCamera() => ColoredBox(
        key: const Key('map-placing'),
        color: NaTheme.of(context).colors.background,
      ),
      MapDrawn(:final initial, :final myLocation) => surface(
        initial: initial,
        myLocation: myLocation,
        markers: ref.watch(mapSearchProvider.select((state) => state.markers)),
        events: ref.read(mapSearchProvider.notifier),
      ),
    };
  }
}

final class PlaceSearchBar extends ConsumerWidget {
  const PlaceSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(placeSearchProvider.select((state) => state.query));
    return ColoredBox(
      color: NaTheme.of(context).colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: NaSearchField(
          key: const Key('map-place-search'),
          text: NaInputText(query.value),
          placeholder: NaLabel(l10n.mapsearchSearch),
          clearLabel: NaLabel(l10n.mapClearSearch),
          onChanged: (text) => ref
              .read(placeSearchProvider.notifier)
              .type(query: PlaceQuery(text.value)),
        ),
      ),
    );
  }
}

final class PlaceSuggestionList extends ConsumerWidget {
  const PlaceSuggestionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    placeSearchProvider.select((state) => state.suggestions),
  )) {
    NoSuggestions() => const SizedBox.shrink(),
    Suggestions(:final predictions) => Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        key: const Key('place-suggestions'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, prediction) in predictions.indexed)
              PlaceSuggestionRow(
                key: Key('place-suggestion-$index'),
                prediction: prediction,
              ),
          ],
        ),
      ),
    ),
  };
}

final class PlaceSuggestionRow extends ConsumerWidget {
  const PlaceSuggestionRow({required this.prediction, super.key});

  final PlacePrediction prediction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          unawaited(
            ref
                .read(placeSearchProvider.notifier)
                .choose(prediction: prediction),
          );
        },
        child: NaListBlock(
          child: Text(
            prediction.description.value,
            style: theme.typography.body.copyWith(color: theme.colors.ink),
          ),
        ),
      ),
    );
  }
}

final class MapSearchFailure extends ConsumerWidget {
  const MapSearchFailure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(
      mapSearchProvider.select((state) => state.status),
    )) {
      MapSearchStatus.failed => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          key: const Key('map-search-failed'),
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NaErrorState(message: l10n.meetingsLoadFailed),
              NaButton(
                key: const Key('map-search-retry'),
                label: l10n.tryAgain,
                onPressed: () => ref.read(mapSearchProvider.notifier).retry(),
              ),
            ],
          ),
        ),
      ),
      MapSearchStatus.notSearched ||
      MapSearchStatus.searching ||
      MapSearchStatus.searched => const SizedBox.shrink(),
    };
  }
}
