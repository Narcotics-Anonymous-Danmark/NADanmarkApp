import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

enum OnlyStarted { on, off }

enum SpeakSort { newest, oldest, name }

enum FilterPanel { open, closed }

extension type const SearchInput(String text) {
  List<FoldedText> get terms => FeedText(text).folded.terms;

  TextPresence get presence => FeedText(text.trim()).presence;
}

extension type const ShownCount(int value) {
  static const ShownCount firstPage = ShownCount(40);

  ShownCount get next => ShownCount(value + firstPage.value);
}

@immutable
final class SpeakSelection {
  const SpeakSelection({
    required this.query,
    required this.languages,
    required this.conventions,
    required this.years,
    required this.onlyStarted,
    required this.sort,
  });

  static const SpeakSelection initial = SpeakSelection(
    query: SearchInput(''),
    languages: {},
    conventions: {},
    years: {},
    onlyStarted: OnlyStarted.off,
    sort: SpeakSort.newest,
  );

  static const SetEquality<SpeakLanguage> _languages = SetEquality();
  static const SetEquality<ConventionKey> _conventions = SetEquality();
  static const SetEquality<SpeakYear> _years = SetEquality();

  final SearchInput query;
  final Set<SpeakLanguage> languages;
  final Set<ConventionKey> conventions;
  final Set<SpeakYear> years;
  final OnlyStarted onlyStarted;
  final SpeakSort sort;

  SpeakSelection withQuery({required SearchInput query}) => SpeakSelection(
    query: query,
    languages: languages,
    conventions: conventions,
    years: years,
    onlyStarted: onlyStarted,
    sort: sort,
  );

  SpeakSelection withLanguages({required Set<SpeakLanguage> languages}) =>
      SpeakSelection(
        query: query,
        languages: Set.unmodifiable(languages),
        conventions: conventions,
        years: years,
        onlyStarted: onlyStarted,
        sort: sort,
      );

  SpeakSelection withConventions({required Set<ConventionKey> conventions}) =>
      SpeakSelection(
        query: query,
        languages: languages,
        conventions: Set.unmodifiable(conventions),
        years: years,
        onlyStarted: onlyStarted,
        sort: sort,
      );

  SpeakSelection withYears({required Set<SpeakYear> years}) => SpeakSelection(
    query: query,
    languages: languages,
    conventions: conventions,
    years: Set.unmodifiable(years),
    onlyStarted: onlyStarted,
    sort: sort,
  );

  SpeakSelection withOnlyStarted({required OnlyStarted onlyStarted}) =>
      SpeakSelection(
        query: query,
        languages: languages,
        conventions: conventions,
        years: years,
        onlyStarted: onlyStarted,
        sort: sort,
      );

  SpeakSelection withSort({required SpeakSort sort}) => SpeakSelection(
    query: query,
    languages: languages,
    conventions: conventions,
    years: years,
    onlyStarted: onlyStarted,
    sort: sort,
  );

  @override
  int get hashCode => Object.hash(
    query,
    _languages.hash(languages),
    _conventions.hash(conventions),
    _years.hash(years),
    onlyStarted,
    sort,
  );

  @override
  bool operator ==(Object other) =>
      other is SpeakSelection &&
      other.query == query &&
      _languages.equals(other.languages, languages) &&
      _conventions.equals(other.conventions, conventions) &&
      _years.equals(other.years, years) &&
      other.onlyStarted == onlyStarted &&
      other.sort == sort;

  @override
  String toString() =>
      'SpeakSelection("${query.text}", $languages, $conventions, $years, '
      '${onlyStarted.name}, ${sort.name})';
}

@immutable
final class SpeakFilters {
  const SpeakFilters({
    required this.typed,
    required this.selection,
    required this.panel,
    required this.shown,
  });

  static const SpeakFilters initial = SpeakFilters(
    typed: SearchInput(''),
    selection: SpeakSelection.initial,
    panel: FilterPanel.closed,
    shown: ShownCount.firstPage,
  );

  static const Duration queryDelay = Duration(milliseconds: 200);

  final SearchInput typed;
  final SpeakSelection selection;
  final FilterPanel panel;
  final ShownCount shown;

  SpeakFilters withSelection({required SpeakSelection selection}) =>
      SpeakFilters(
        typed: typed,
        selection: selection,
        panel: panel,
        shown: ShownCount.firstPage,
      );

  SpeakFilters withTyped({required SearchInput typed}) => SpeakFilters(
    typed: typed,
    selection: selection,
    panel: panel,
    shown: shown,
  );

  SpeakFilters withPanel({required FilterPanel panel}) => SpeakFilters(
    typed: typed,
    selection: selection,
    panel: panel,
    shown: shown,
  );

  SpeakFilters withShown({required ShownCount shown}) => SpeakFilters(
    typed: typed,
    selection: selection,
    panel: panel,
    shown: shown,
  );

  @override
  int get hashCode => Object.hash(typed, selection, panel, shown);

  @override
  bool operator ==(Object other) =>
      other is SpeakFilters &&
      other.typed == typed &&
      other.selection == selection &&
      other.panel == panel &&
      other.shown == shown;

  @override
  String toString() =>
      'SpeakFilters("${typed.text}", $selection, ${panel.name}, '
      '${shown.value})';
}

final Provider<Debouncer> speakQueryDebouncerProvider = Provider.autoDispose((
  ref,
) {
  final debouncer = ref
      .read(schedulerProvider)
      .debounce(window: SpeakFilters.queryDelay);
  ref.onDispose(debouncer.dispose);
  return debouncer;
});

final NotifierProvider<SpeakFiltersController, SpeakFilters>
speakFiltersProvider = NotifierProvider.autoDispose(
  SpeakFiltersController.new,
);

final class SpeakFiltersController extends Notifier<SpeakFilters> {
  Debouncer get _debouncer => ref.read(speakQueryDebouncerProvider);

  SpeakSelection get _selection => state.selection;

  @override
  SpeakFilters build() {
    ref.watch(speakQueryDebouncerProvider);
    return SpeakFilters.initial;
  }

  void type({required SearchInput text}) {
    state = state.withTyped(typed: text);
    _debouncer(
      action: () => _select(selection: _selection.withQuery(query: text)),
    );
  }

  void toggleLanguage({required SpeakLanguage language}) => _select(
    selection: _selection.withLanguages(
      languages: _toggled(values: _selection.languages, value: language),
    ),
  );

  void clearLanguages() =>
      _select(selection: _selection.withLanguages(languages: const {}));

  void toggleConvention({required ConventionKey convention}) => _select(
    selection: _selection.withConventions(
      conventions: _toggled(values: _selection.conventions, value: convention),
    ),
  );

  void clearConventions() =>
      _select(selection: _selection.withConventions(conventions: const {}));

  void toggleYear({required SpeakYear year}) => _select(
    selection: _selection.withYears(
      years: _toggled(values: _selection.years, value: year),
    ),
  );

  void clearYears() =>
      _select(selection: _selection.withYears(years: const {}));

  void sortBy({required SpeakSort sort}) =>
      _select(selection: _selection.withSort(sort: sort));

  void toggleOnlyStarted() => _select(
    selection: _selection.withOnlyStarted(
      onlyStarted: switch (_selection.onlyStarted) {
        OnlyStarted.on => OnlyStarted.off,
        OnlyStarted.off => OnlyStarted.on,
      },
    ),
  );

  void reset() {
    _debouncer(action: () {});
    state = state.withTyped(typed: const SearchInput(''));
    _select(selection: SpeakSelection.initial);
  }

  void togglePanel() => state = state.withPanel(
    panel: switch (state.panel) {
      FilterPanel.open => FilterPanel.closed,
      FilterPanel.closed => FilterPanel.open,
    },
  );

  void showMore({required ShownCount after}) {
    if (state.shown == after) {
      state = state.withShown(shown: after.next);
    }
  }

  void _select({required SpeakSelection selection}) {
    if (selection != state.selection) {
      state = state.withSelection(selection: selection);
    }
  }

  static Set<T> _toggled<T>({required Set<T> values, required T value}) =>
      values.contains(value)
      ? Set.unmodifiable(values.where((existing) => existing != value))
      : Set.unmodifiable({...values, value});
}
