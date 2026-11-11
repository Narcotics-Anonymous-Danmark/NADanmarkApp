import 'package:collection/collection.dart';
import 'package:feature_speaks/src/application/speak_filters.dart';
import 'package:feature_speaks/src/application/speak_resumes.dart';
import 'package:feature_speaks/src/application/speak_texts.dart';
import 'package:feature_speaks/src/application/speaks_catalog_loader.dart';
import 'package:meta/meta.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

enum MoreSpeaks { available, none }

enum FiltersInUse { yes, no }

extension type const FilterCount(int value) {}

extension type const SectionIndex(int value) {}

@immutable
final class SpeakSection {
  const SpeakSection({required this.convention, required this.speaks});

  final SpeakConvention convention;
  final List<Speak> speaks;

  static const ListEquality<Speak> _speaks = ListEquality();

  @override
  int get hashCode => Object.hash(convention, _speaks.hash(speaks));

  @override
  bool operator ==(Object other) =>
      other is SpeakSection &&
      other.convention == convention &&
      _speaks.equals(other.speaks, speaks);

  @override
  String toString() =>
      'SpeakSection(${convention.key.value}, ${speaks.length})';
}

@immutable
final class SpeakListing {
  const SpeakListing({
    required this.matchCount,
    required this.sections,
    required this.more,
    required this.yearOptions,
    required this.activeFilters,
    required this.inUse,
  });

  factory SpeakListing.of({
    required SpeakCatalog catalog,
    required SpeakFilters filters,
    required Set<PlaylistId> started,
    required SpeakTexts texts,
  }) {
    final selection = filters.selection;
    final existing = catalog.conventions.map((convention) => convention.key);
    final conventions = selection.conventions.where(existing.contains).toSet();
    final terms = selection.query.terms;
    final order = Map.fromEntries(
      catalog.conventions.indexed.map(
        (indexed) => MapEntry(indexed.$2.key, SectionIndex(indexed.$1)),
      ),
    );
    _Ranked ranked(Speak speak) => _Ranked(
      speak: speak,
      section: order[speak.convention] ?? const SectionIndex(0),
      title: texts.title(speak: speak),
    );
    final selected = catalog.speaks.where(
      (speak) =>
          (selection.languages.isEmpty ||
              selection.languages.contains(speak.language)) &&
          (conventions.isEmpty || conventions.contains(speak.convention)) &&
          (selection.onlyStarted == OnlyStarted.off ||
              started.contains(speak.id)) &&
          terms.every((term) => speak.searchText.value.contains(term.value)),
    );
    final matches = selected
        .where(
          (speak) =>
              selection.years.isEmpty ||
              speak.date.years.any(selection.years.contains),
        )
        .map(ranked)
        .sorted((a, b) => a.compareTo(other: b, sort: selection.sort))
        .map((rank) => rank.speak)
        .toList();
    final visible = matches.take(filters.shown.value).toList();
    final activeFilters = FilterCount(
      selection.languages.length +
          conventions.length +
          selection.years.length +
          switch (selection.onlyStarted) {
            OnlyStarted.on => 1,
            OnlyStarted.off => 0,
          },
    );
    return SpeakListing(
      matchCount: SpeakCount(matches.length),
      sections: List.unmodifiable(
        visible
            .splitBetween((a, b) => a.convention != b.convention)
            .map(
              (speaks) => SpeakSection(
                convention: catalog.conventionOf(key: speaks.first.convention),
                speaks: List.unmodifiable(speaks),
              ),
            ),
      ),
      more: matches.length > visible.length
          ? MoreSpeaks.available
          : MoreSpeaks.none,
      yearOptions: List.unmodifiable(
        {
          ...selected.expand((speak) => speak.date.years),
          ...selection.years,
        }.sorted((a, b) => b.value.compareTo(a.value)),
      ),
      activeFilters: activeFilters,
      inUse:
          activeFilters.value > 0 ||
              filters.typed.presence == TextPresence.present
          ? FiltersInUse.yes
          : FiltersInUse.no,
    );
  }

  static const ListEquality<SpeakSection> _sections = ListEquality();
  static const ListEquality<SpeakYear> _years = ListEquality();

  final SpeakCount matchCount;
  final List<SpeakSection> sections;
  final MoreSpeaks more;
  final List<SpeakYear> yearOptions;
  final FilterCount activeFilters;
  final FiltersInUse inUse;

  @override
  int get hashCode => Object.hash(
    matchCount,
    _sections.hash(sections),
    more,
    _years.hash(yearOptions),
    activeFilters,
    inUse,
  );

  @override
  bool operator ==(Object other) =>
      other is SpeakListing &&
      other.matchCount == matchCount &&
      _sections.equals(other.sections, sections) &&
      other.more == more &&
      _years.equals(other.yearOptions, yearOptions) &&
      other.activeFilters == activeFilters &&
      other.inUse == inUse;

  @override
  String toString() =>
      'SpeakListing(${matchCount.value}, $sections, ${more.name})';
}

final ProviderFamily<SpeakListing, Language> speakListingProvider = Provider
    .autoDispose
    .family(
      (ref, language) => SpeakListing.of(
        catalog: ref.watch(speaksCatalogProvider).catalogOrEmpty,
        filters: ref.watch(speakFiltersProvider),
        started: ref.watch(
          speakResumesProvider.select((resumes) => resumes.started),
        ),
        texts: SpeakTexts.of(language: language),
      ),
    );

final class _Ranked {
  _Ranked({required this.speak, required this.section, required this.title})
    : folded = FeedText(title.value).folded;

  final Speak speak;
  final SectionIndex section;
  final NaLabel title;
  final FoldedText folded;

  int compareTo({required _Ranked other, required SpeakSort sort}) =>
      switch (section.value.compareTo(other.section.value)) {
        0 => switch (sort) {
          SpeakSort.name => _byTitle(other: other),
          SpeakSort.newest || SpeakSort.oldest => _byDate(
            other: other,
            sort: sort,
          ),
        },
        final int bySection => bySection,
      };

  int _byTitle({required _Ranked other}) =>
      switch (folded.value.compareTo(other.folded.value)) {
        0 => title.value.compareTo(other.title.value),
        final int byFolded => byFolded,
      };

  int _byDate({required _Ranked other, required SpeakSort sort}) =>
      switch ((speak.date.sortKey.value, other.speak.date.sortKey.value)) {
        (0, 0) => _byTitle(other: other),
        (0, int()) => 1,
        (int(), 0) => -1,
        (final int left, final int right) when left == right => _byTitle(
          other: other,
        ),
        (final int left, final int right) => switch (sort) {
          SpeakSort.oldest => left.compareTo(right),
          SpeakSort.newest || SpeakSort.name => right.compareTo(left),
        },
      };
}
