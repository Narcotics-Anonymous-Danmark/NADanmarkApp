import 'dart:async';

import 'package:collection/collection.dart';
import 'package:feature_meetings_map/src/application/map_search_controller.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<PlaceSearchController, PlaceSearchState>
placeSearchProvider = NotifierProvider.autoDispose(PlaceSearchController.new);

final Provider<Debouncer> placeSearchDebouncerProvider = Provider.autoDispose((
  ref,
) {
  final debouncer = ref
      .read(schedulerProvider)
      .debounce(window: PlaceSearchController.typingPause);
  ref.onDispose(debouncer.dispose);
  return debouncer;
});

@immutable
sealed class PlaceSuggestions {
  const PlaceSuggestions();
}

final class NoSuggestions extends PlaceSuggestions {
  const NoSuggestions();

  @override
  int get hashCode => (NoSuggestions).hashCode;

  @override
  bool operator ==(Object other) => other is NoSuggestions;
}

final class Suggestions extends PlaceSuggestions {
  Suggestions({required List<PlacePrediction> predictions})
    : predictions = List.unmodifiable(predictions);

  final List<PlacePrediction> predictions;

  @override
  int get hashCode => Object.hashAll(predictions);

  @override
  bool operator ==(Object other) =>
      other is Suggestions &&
      const ListEquality<PlacePrediction>().equals(
        other.predictions,
        predictions,
      );
}

@immutable
final class PlaceSearchState {
  const PlaceSearchState({required this.query, required this.suggestions});

  final PlaceQuery query;
  final PlaceSuggestions suggestions;

  @override
  int get hashCode => Object.hash(query, suggestions);

  @override
  bool operator ==(Object other) =>
      other is PlaceSearchState &&
      other.query == query &&
      other.suggestions == suggestions;
}

final class _Lookup {
  _Lookup();
}

final class PlaceSearchController extends Notifier<PlaceSearchState> {
  static const Duration typingPause = Duration(milliseconds: 300);

  _Lookup _lookup = _Lookup();

  @override
  PlaceSearchState build() {
    ref.watch(placeSearchDebouncerProvider);
    return const PlaceSearchState(
      query: PlaceQuery.empty,
      suggestions: NoSuggestions(),
    );
  }

  void type({required PlaceQuery query}) {
    _lookup = _Lookup();
    switch (query.value.trim()) {
      case '':
        state = PlaceSearchState(
          query: query,
          suggestions: const NoSuggestions(),
        );
      case String():
        state = PlaceSearchState(query: query, suggestions: state.suggestions);
        ref
            .read(placeSearchDebouncerProvider)
            .call(action: () => _suggestIfCurrent(query: query));
    }
  }

  Future<void> choose({required PlacePrediction prediction}) async {
    _lookup = _Lookup();
    state = PlaceSearchState(
      query: PlaceQuery(prediction.description.value),
      suggestions: const NoSuggestions(),
    );
    final located = await ref
        .read(placesPortProvider)
        .locate(place: prediction.id);
    if (!ref.mounted) {
      return;
    }
    switch (located) {
      case Ok(:final value):
        await ref
            .read(mapSearchProvider.notifier)
            .showPlace(description: prediction.description, point: value);
      case Err():
        break;
    }
  }

  void _suggestIfCurrent({required PlaceQuery query}) {
    if (ref.mounted && state.query == query) {
      unawaited(_suggest(query: query));
    }
  }

  Future<void> _suggest({required PlaceQuery query}) async {
    final lookup = _Lookup();
    _lookup = lookup;
    final settings = await ref.read(settingsPortProvider).read();
    if (!ref.mounted || !identical(lookup, _lookup)) {
      return;
    }
    final outcome = await ref
        .read(placesPortProvider)
        .predictions(query: query, language: settings.language);
    if (!ref.mounted || !identical(lookup, _lookup)) {
      return;
    }
    state = PlaceSearchState(
      query: state.query,
      suggestions: switch (outcome) {
        Ok(:final value) when value.isNotEmpty => Suggestions(
          predictions: value,
        ),
        Ok() || Err() => const NoSuggestions(),
      },
    );
  }
}
