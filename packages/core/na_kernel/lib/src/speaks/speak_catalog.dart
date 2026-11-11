import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/speaks/feed_text.dart';
import 'package:na_kernel/src/speaks/speak_feed.dart';
import 'package:na_kernel/src/speaks/speak_values.dart';

@immutable
final class ParsedConvention {
  const ParsedConvention({
    required this.key,
    required this.label,
    required this.city,
  });

  factory ParsedConvention.of({required FeedText title}) {
    final base = FeedText(
      title.tidied.value.replaceFirst(_foreignSuffix, ''),
    );
    final split = _citySplit.firstMatch(base.value);
    final named = switch (split) {
      final RegExpMatch match => FeedText(match.group(1) ?? '').tidied,
      null => base.tidied,
    };
    final convention = switch (named.presence) {
      TextPresence.present => named,
      TextPresence.blank => _defaultBase,
    };
    final key = convention.folded;
    return ParsedConvention(
      key: ConventionKey(key.value.isEmpty ? _defaultKey : key.value),
      label: ConventionLabel(convention.prettyLabel.value),
      city: switch (split) {
        final RegExpMatch match => switch (FeedText(
          match.group(2) ?? '',
        ).tidied) {
          final FeedText city when city.presence == TextPresence.present =>
            InCity(name: CityName(city.prettyLabel.value)),
          FeedText() => const NoCity(),
        },
        null => const NoCity(),
      },
    );
  }

  static final RegExp _foreignSuffix = RegExp(
    r'[\s-]*udenlandske\s+speaks?$',
    caseSensitive: false,
  );
  static final RegExp _citySplit = RegExp(r'^(.*?)(?:\s+-\s*|\s*-\s+)(.*)$');
  static const FeedText _defaultBase = FeedText('Speaks');
  static const String _defaultKey = 'speaks';

  final ConventionKey key;
  final ConventionLabel label;
  final ConventionCity city;

  @override
  int get hashCode => Object.hash(key, label, city);

  @override
  bool operator ==(Object other) =>
      other is ParsedConvention &&
      other.key == key &&
      other.label == label &&
      other.city == city;

  @override
  String toString() => 'ParsedConvention(${key.value}, ${label.text}, $city)';
}

DetectedKind detectKind({required List<FeedText> candidates}) =>
    candidates
        .map((candidate) => _kindIn(text: candidate.folded))
        .firstWhereOrNull((kind) => kind is KindOf) ??
    const NoKind();

final RegExp _opening = RegExp('abning|opening');
final RegExp _closing = RegExp('afslutning|closing');
final RegExp _main = RegExp('hovedspeak|hoved speak|main speak');

DetectedKind _kindIn({required FoldedText text}) =>
    _opening.hasMatch(
      text.value,
    )
    ? const KindOf(kind: SpeakKind.opening)
    : _closing.hasMatch(text.value)
    ? const KindOf(kind: SpeakKind.closing)
    : _main.hasMatch(text.value)
    ? const KindOf(kind: SpeakKind.main)
    : const NoKind();

final RegExp _kindPrefix = RegExp(
  r'^\s*(?:åbnings?|abnings?|opening|afslutnings?|closing|hoved|main)'
  r'\s*speak(?:er)?\b[\s:,.-]*',
  caseSensitive: false,
);

Speaker speakerOf({required FeedText name}) =>
    switch (FeedText(name.tidied.value.replaceFirst(_kindPrefix, '')).tidied) {
      final FeedText speaker when speaker.presence == TextPresence.present =>
        NamedSpeaker(name: SpeakerName(speaker.value)),
      FeedText() => const NoSpeaker(),
    };

final RegExp _extension = RegExp(r'\.[a-z0-9]+$', caseSensitive: false);

FeedText fileNameOf({required AudioUrl url}) => FeedText(
  Uri.decodeQueryComponent(
    url.uri.path.split('/').last.replaceAll('+', '%2B'),
    encoding: const Utf8Codec(allowMalformed: true),
  ).replaceFirst(_extension, ''),
);

SpeakEdition editionOf({required FeedText location}) =>
    switch (location.tidied) {
      final FeedText raw
          when raw.presence == TextPresence.present && raw.value != '?' =>
        EditionOf(text: EditionText(raw.prettyEdition.value)),
      FeedText() => const NoEdition(),
    };

final RegExp _anyYear = RegExp(r'(19|20)\d{2}');

SpeakEdition shortEditionOf({
  required SpeakEdition edition,
  required ConventionLabel label,
}) => switch (edition) {
  EditionOf(:final text)
      when label.text.isNotEmpty &&
          text.text.toLowerCase().startsWith(label.text.toLowerCase()) =>
    switch (FeedText(text.text.substring(label.text.length)).tidied) {
      final FeedText rest when _anyYear.hasMatch(rest.value) => EditionOf(
        text: EditionText(rest.value),
      ),
      FeedText() => edition,
    },
  EditionOf() || NoEdition() => edition,
};

SpeakTitle titleOf({
  required Speaker speaker,
  required DetectedKind kind,
  required SpeakEdition edition,
  required ConventionLabel label,
}) => switch ((speaker, kind, edition)) {
  (NamedSpeaker(:final name), DetectedKind(), SpeakEdition()) => SpeakerTitle(
    name: name,
  ),
  (NoSpeaker(), KindOf(:final kind), SpeakEdition()) => KindTitle(kind: kind),
  (NoSpeaker(), NoKind(), EditionOf(:final text)) => EditionTitle(
    edition: text,
  ),
  (NoSpeaker(), NoKind(), NoEdition()) => ConventionTitle(label: label),
};

List<MetaPart> metaOf({
  required SpeakEdition edition,
  required SpeakDate date,
}) => List.unmodifiable([
  ...switch (edition) {
    EditionOf(:final text) => [MetaPart(text.text)],
    NoEdition() => const <MetaPart>[],
  },
  ...date.timeLabels.where(
    (time) => switch (edition) {
      EditionOf(:final text) => !FeedText(
        text.text,
      ).folded.value.contains(FeedText(time.text).folded.value),
      NoEdition() => true,
    },
  ),
]);

List<MetaPart> contextOf({
  required List<MetaPart> meta,
  required ConventionLabel label,
}) => meta.isEmpty
    ? List.unmodifiable([MetaPart(label.text)])
    : meta
          .map((part) => part.text)
          .join(Speak.separator)
          .toLowerCase()
          .startsWith(label.text.toLowerCase())
    ? meta
    : List.unmodifiable([MetaPart(label.text), ...meta]);

@immutable
final class Speak {
  const Speak({
    required this.id,
    required this.url,
    required this.title,
    required this.speaker,
    required this.kind,
    required this.convention,
    required this.conventionLabel,
    required this.groupTitle,
    required this.edition,
    required this.date,
    required this.meta,
    required this.context,
    required this.language,
    required this.searchText,
  });

  factory Speak.of({
    required FeedGroup group,
    required ParsedConvention convention,
    required FeedEntry entry,
    required SpeakKindWords kindWords,
  }) {
    final name = entry.name.tidied;
    final location = entry.location.tidied;
    final fileName = fileNameOf(url: entry.url);
    final kind = detectKind(candidates: [name, location, fileName]);
    final speaker = speakerOf(name: name);
    final date = SpeakDate.parse(
      field: entry.year,
      fallback: FeedText.join(parts: [location, fileName]),
    );
    final edition = shortEditionOf(
      edition: editionOf(location: location),
      label: convention.label,
    );
    final title = titleOf(
      speaker: speaker,
      kind: kind,
      edition: edition,
      label: convention.label,
    );
    final meta = metaOf(edition: edition, date: date);
    final groupTitle = group.title.tidied;
    return Speak(
      id: entry.id,
      url: entry.url,
      title: title,
      speaker: speaker,
      kind: kind,
      convention: convention.key,
      conventionLabel: convention.label,
      groupTitle: GroupTitle(groupTitle.value),
      edition: edition,
      date: date,
      meta: meta,
      context: contextOf(meta: meta, label: convention.label),
      language: group.language,
      searchText: FeedText.join(
        parts: [
          switch (title) {
            SpeakerTitle(:final name) => FeedText(name.text),
            KindTitle() => const FeedText(''),
            EditionTitle(:final edition) => FeedText(edition.text),
            ConventionTitle(:final label) => FeedText(label.text),
          },
          switch (speaker) {
            NamedSpeaker(:final name) => FeedText(name.text),
            NoSpeaker() => const FeedText(''),
          },
          switch (kind) {
            KindOf(:final kind) => FeedText(kindWords.of(kind: kind).value),
            NoKind() => const FeedText(''),
          },
          location,
          groupTitle,
          FeedText(convention.label.text),
          switch (convention.city) {
            InCity(:final name) => FeedText(name.text),
            NoCity() => const FeedText(''),
          },
          ...date.years.map((year) => FeedText('${year.value}')),
          ...date.dateLabels.map((label) => FeedText(label.text)),
          FeedText(group.language.searchWords.value),
          fileName,
        ],
      ).folded,
    );
  }

  static const String separator = ' · ';

  static const ListEquality<MetaPart> _parts = ListEquality();

  final PlaylistId id;
  final AudioUrl url;
  final SpeakTitle title;
  final Speaker speaker;
  final DetectedKind kind;
  final ConventionKey convention;
  final ConventionLabel conventionLabel;
  final GroupTitle groupTitle;
  final SpeakEdition edition;
  final SpeakDate date;
  final List<MetaPart> meta;
  final List<MetaPart> context;
  final SpeakLanguage language;
  final FoldedText searchText;

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    speaker,
    kind,
    convention,
    conventionLabel,
    groupTitle,
    edition,
    date,
    _parts.hash(meta),
    _parts.hash(context),
    language,
    searchText,
  );

  @override
  bool operator ==(Object other) =>
      other is Speak &&
      other.id == id &&
      other.url == url &&
      other.title == title &&
      other.speaker == speaker &&
      other.kind == kind &&
      other.convention == convention &&
      other.conventionLabel == conventionLabel &&
      other.groupTitle == groupTitle &&
      other.edition == edition &&
      other.date == date &&
      _parts.equals(other.meta, meta) &&
      _parts.equals(other.context, context) &&
      other.language == language &&
      other.searchText == searchText;

  @override
  String toString() => 'Speak(${id.value}, $title)';
}

@immutable
final class SpeakConvention {
  const SpeakConvention({
    required this.key,
    required this.label,
    required this.city,
    required this.count,
  });

  final ConventionKey key;
  final ConventionLabel label;
  final ConventionCity city;
  final SpeakCount count;

  @override
  int get hashCode => Object.hash(key, label, city, count);

  @override
  bool operator ==(Object other) =>
      other is SpeakConvention &&
      other.key == key &&
      other.label == label &&
      other.city == city &&
      other.count == count;

  @override
  String toString() =>
      'SpeakConvention(${key.value}, ${label.text}, $city, ${count.value})';
}

typedef _Source = ({FeedGroup group, ParsedConvention convention});

typedef _Candidate = ({_Source source, FeedEntry entry});

@immutable
final class SpeakCatalog {
  const SpeakCatalog({
    required this.speaks,
    required this.conventions,
    required this.years,
  });

  factory SpeakCatalog.build({
    required List<FeedGroup> groups,
    required SpeakKindWords kindWords,
  }) {
    final parsed = List<_Source>.unmodifiable(
      groups.map(
        (group) => (
          group: group,
          convention: ParsedConvention.of(title: group.title),
        ),
      ),
    );
    final candidates = List<_Candidate>.unmodifiable(
      parsed.expand(
        (source) => source.group.entries.map(
          (entry) => (source: source, entry: entry),
        ),
      ),
    );
    final firstIndex = Map.fromEntries(
      candidates.indexed.toList().reversed.map(
        (indexed) => MapEntry(indexed.$2.entry.id, indexed.$1),
      ),
    );
    final speaks = List<Speak>.unmodifiable(
      candidates.indexed
          .where((indexed) => firstIndex[indexed.$2.entry.id] == indexed.$1)
          .map(
            (indexed) => Speak.of(
              group: indexed.$2.source.group,
              convention: indexed.$2.source.convention,
              entry: indexed.$2.entry,
              kindWords: kindWords,
            ),
          ),
    );
    return SpeakCatalog(
      speaks: speaks,
      conventions: List.unmodifiable(
        parsed
            .map((source) => source.convention.key)
            .toSet()
            .map(
              (key) => _conventionOf(
                key: key,
                parsed: parsed
                    .map((source) => source.convention)
                    .where((convention) => convention.key == key)
                    .toList(),
                speaks: speaks,
              ),
            )
            .where((convention) => convention.count.value > 0),
      ),
      years: List.unmodifiable(
        speaks
            .expand((speak) => speak.date.years)
            .toSet()
            .sorted((a, b) => b.value.compareTo(a.value)),
      ),
    );
  }

  static const SpeakCatalog empty = SpeakCatalog(
    speaks: [],
    conventions: [],
    years: [],
  );

  static SpeakConvention _conventionOf({
    required ConventionKey key,
    required List<ParsedConvention> parsed,
    required List<Speak> speaks,
  }) => SpeakConvention(
    key: key,
    label: parsed.first.label,
    city:
        parsed
            .map((convention) => convention.city)
            .firstWhereOrNull((city) => city is InCity) ??
        const NoCity(),
    count: SpeakCount(
      speaks.where((speak) => speak.convention == key).length,
    ),
  );

  static const ListEquality<Speak> _speaks = ListEquality();
  static const ListEquality<SpeakConvention> _conventions = ListEquality();
  static const ListEquality<SpeakYear> _years = ListEquality();

  final List<Speak> speaks;
  final List<SpeakConvention> conventions;
  final List<SpeakYear> years;

  SpeakConvention conventionOf({required ConventionKey key}) =>
      conventions.firstWhere(
        (convention) => convention.key == key,
        orElse: () => SpeakConvention(
          key: key,
          label: ConventionLabel(key.value),
          city: const NoCity(),
          count: const SpeakCount(0),
        ),
      );

  @override
  int get hashCode => Object.hash(
    _speaks.hash(speaks),
    _conventions.hash(conventions),
    _years.hash(years),
  );

  @override
  bool operator ==(Object other) =>
      other is SpeakCatalog &&
      _speaks.equals(other.speaks, speaks) &&
      _conventions.equals(other.conventions, conventions) &&
      _years.equals(other.years, years);

  @override
  String toString() =>
      'SpeakCatalog(${speaks.length} speaks, '
      '${conventions.length} conventions)';
}
