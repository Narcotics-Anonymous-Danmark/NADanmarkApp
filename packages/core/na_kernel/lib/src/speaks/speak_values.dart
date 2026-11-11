import 'package:meta/meta.dart';
import 'package:na_kernel/src/speaks/feed_text.dart';
import 'package:na_kernel/src/time/local_date.dart';

extension type const FeedExcerpt(String value) {}

enum SpeakLanguage {
  danish(
    code: 'da',
    excerpt: FeedExcerpt('NA-SPEAKS-DK'),
    searchWords: FoldedText('dansk danish'),
  ),
  english(
    code: 'en',
    excerpt: FeedExcerpt('NA-SPEAKS-EN'),
    searchWords: FoldedText('english engelsk udenlandske'),
  )
  ;

  const SpeakLanguage({
    required this.code,
    required this.excerpt,
    required this.searchWords,
  });

  final String code;
  final FeedExcerpt excerpt;
  final FoldedText searchWords;
}

enum SpeakKind { opening, main, closing }

@immutable
sealed class DetectedKind {
  const DetectedKind();
}

final class KindOf extends DetectedKind {
  const KindOf({required this.kind});

  final SpeakKind kind;

  @override
  int get hashCode => Object.hash(KindOf, kind);

  @override
  bool operator ==(Object other) => other is KindOf && other.kind == kind;

  @override
  String toString() => 'KindOf(${kind.name})';
}

final class NoKind extends DetectedKind {
  const NoKind();

  @override
  int get hashCode => (NoKind).hashCode;

  @override
  bool operator ==(Object other) => other is NoKind;

  @override
  String toString() => 'NoKind';
}

@immutable
final class SpeakKindWords {
  const SpeakKindWords({
    required this.opening,
    required this.main,
    required this.closing,
  });

  final FoldedText opening;
  final FoldedText main;
  final FoldedText closing;

  FoldedText of({required SpeakKind kind}) => switch (kind) {
    SpeakKind.opening => opening,
    SpeakKind.main => main,
    SpeakKind.closing => closing,
  };

  @override
  int get hashCode => Object.hash(opening, main, closing);

  @override
  bool operator ==(Object other) =>
      other is SpeakKindWords &&
      other.opening == opening &&
      other.main == main &&
      other.closing == closing;
}

extension type const SpeakerName(String text) {}

@immutable
sealed class Speaker {
  const Speaker();
}

final class NamedSpeaker extends Speaker {
  const NamedSpeaker({required this.name});

  final SpeakerName name;

  @override
  int get hashCode => Object.hash(NamedSpeaker, name);

  @override
  bool operator ==(Object other) => other is NamedSpeaker && other.name == name;

  @override
  String toString() => 'NamedSpeaker(${name.text})';
}

final class NoSpeaker extends Speaker {
  const NoSpeaker();

  @override
  int get hashCode => (NoSpeaker).hashCode;

  @override
  bool operator ==(Object other) => other is NoSpeaker;

  @override
  String toString() => 'NoSpeaker';
}

extension type const ConventionKey(String value) {}

extension type const ConventionLabel(String text) {}

extension type const CityName(String text) {}

extension type const GroupTitle(String text) {}

extension type const EditionText(String text) {}

extension type const MetaPart(String text) {}

extension type const SpeakCount(int value) {}

@immutable
sealed class ConventionCity {
  const ConventionCity();
}

final class InCity extends ConventionCity {
  const InCity({required this.name});

  final CityName name;

  @override
  int get hashCode => Object.hash(InCity, name);

  @override
  bool operator ==(Object other) => other is InCity && other.name == name;

  @override
  String toString() => 'InCity(${name.text})';
}

final class NoCity extends ConventionCity {
  const NoCity();

  @override
  int get hashCode => (NoCity).hashCode;

  @override
  bool operator ==(Object other) => other is NoCity;

  @override
  String toString() => 'NoCity';
}

@immutable
sealed class SpeakEdition {
  const SpeakEdition();
}

final class EditionOf extends SpeakEdition {
  const EditionOf({required this.text});

  final EditionText text;

  @override
  int get hashCode => Object.hash(EditionOf, text);

  @override
  bool operator ==(Object other) => other is EditionOf && other.text == text;

  @override
  String toString() => 'EditionOf(${text.text})';
}

final class NoEdition extends SpeakEdition {
  const NoEdition();

  @override
  int get hashCode => (NoEdition).hashCode;

  @override
  bool operator ==(Object other) => other is NoEdition;

  @override
  String toString() => 'NoEdition';
}

extension type const SpeakYear(int value) {}

extension type const SpeakSortKey(int value) {}

@immutable
sealed class SpeakDate {
  const SpeakDate();

  static final RegExp _fullDate = RegExp(
    r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})$',
  );
  static final RegExp _year = RegExp(r'(19|20)\d{2}');

  static SpeakDate parse({
    required FeedText field,
    required FeedText fallback,
  }) {
    final text = field.tidied.value;
    final full = switch (_fullDate.firstMatch(text)) {
      final RegExpMatch match => switch (LocalDate(
        year: switch (int.parse(match.group(3) ?? '')) {
          final int short when short < 100 => short + 2000,
          final int long => long,
        },
        month: int.parse(match.group(2) ?? ''),
        day: int.parse(match.group(1) ?? ''),
      )) {
        final LocalDate date
            when date.day >= 1 &&
                date.day <= 31 &&
                date.month >= 1 &&
                date.month <= 12 =>
          FullDate(date: date),
        LocalDate() => const UnknownDate(),
      },
      null => const UnknownDate(),
    };
    return switch (full) {
      FullDate() => full,
      YearOnly() || UnknownDate() => switch (_year.firstMatch(text) ??
          _year.firstMatch(fallback.value)) {
        final RegExpMatch match => YearOnly(
          year: SpeakYear(int.parse(match.group(0) ?? '')),
        ),
        null => const UnknownDate(),
      },
    };
  }

  SpeakSortKey get sortKey => switch (this) {
    FullDate(:final date) => SpeakSortKey(
      date.year * 10000 + date.month * 100 + date.day,
    ),
    YearOnly(:final year) => SpeakSortKey(year.value * 10000),
    UnknownDate() => const SpeakSortKey(0),
  };

  List<SpeakYear> get years => switch (this) {
    FullDate(:final date) => List.unmodifiable([SpeakYear(date.year)]),
    YearOnly(:final year) => List.unmodifiable([year]),
    UnknownDate() => const [],
  };

  List<MetaPart> get dateLabels => switch (this) {
    FullDate(:final date) => List.unmodifiable([
      MetaPart(
        '${'${date.day}'.padLeft(2, '0')}-'
        '${'${date.month}'.padLeft(2, '0')}-${date.year}',
      ),
    ]),
    YearOnly() || UnknownDate() => const [],
  };

  List<MetaPart> get timeLabels => switch (this) {
    FullDate() => dateLabels,
    YearOnly(:final year) => List.unmodifiable([MetaPart('${year.value}')]),
    UnknownDate() => const [],
  };
}

final class FullDate extends SpeakDate {
  const FullDate({required this.date});

  final LocalDate date;

  @override
  int get hashCode => Object.hash(FullDate, date);

  @override
  bool operator ==(Object other) => other is FullDate && other.date == date;

  @override
  String toString() => 'FullDate($date)';
}

final class YearOnly extends SpeakDate {
  const YearOnly({required this.year});

  final SpeakYear year;

  @override
  int get hashCode => Object.hash(YearOnly, year);

  @override
  bool operator ==(Object other) => other is YearOnly && other.year == year;

  @override
  String toString() => 'YearOnly(${year.value})';
}

final class UnknownDate extends SpeakDate {
  const UnknownDate();

  @override
  int get hashCode => (UnknownDate).hashCode;

  @override
  bool operator ==(Object other) => other is UnknownDate;

  @override
  String toString() => 'UnknownDate';
}

@immutable
sealed class SpeakTitle {
  const SpeakTitle();
}

final class SpeakerTitle extends SpeakTitle {
  const SpeakerTitle({required this.name});

  final SpeakerName name;

  @override
  int get hashCode => Object.hash(SpeakerTitle, name);

  @override
  bool operator ==(Object other) => other is SpeakerTitle && other.name == name;

  @override
  String toString() => 'SpeakerTitle(${name.text})';
}

final class KindTitle extends SpeakTitle {
  const KindTitle({required this.kind});

  final SpeakKind kind;

  @override
  int get hashCode => Object.hash(KindTitle, kind);

  @override
  bool operator ==(Object other) => other is KindTitle && other.kind == kind;

  @override
  String toString() => 'KindTitle(${kind.name})';
}

final class EditionTitle extends SpeakTitle {
  const EditionTitle({required this.edition});

  final EditionText edition;

  @override
  int get hashCode => Object.hash(EditionTitle, edition);

  @override
  bool operator ==(Object other) =>
      other is EditionTitle && other.edition == edition;

  @override
  String toString() => 'EditionTitle(${edition.text})';
}

final class ConventionTitle extends SpeakTitle {
  const ConventionTitle({required this.label});

  final ConventionLabel label;

  @override
  int get hashCode => Object.hash(ConventionTitle, label);

  @override
  bool operator ==(Object other) =>
      other is ConventionTitle && other.label == label;

  @override
  String toString() => 'ConventionTitle(${label.text})';
}
