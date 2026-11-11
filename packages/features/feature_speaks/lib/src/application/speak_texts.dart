import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class SpeakTexts {
  const SpeakTexts({required this.l10n});

  factory SpeakTexts.of({required Language language}) =>
      SpeakTexts(l10n: lookupAppLocalizations(language.locale));

  static const String _separator = Speak.separator;

  final AppLocalizations l10n;

  static SpeakKindWords kindWords() {
    final texts = Language.values.map(
      (language) => SpeakTexts.of(language: language),
    );
    FoldedText words({required SpeakKind kind}) => FeedText.join(
      parts: texts
          .map((text) => FeedText(text.kind(kind: kind).value))
          .toList(),
    ).folded;
    return SpeakKindWords(
      opening: words(kind: SpeakKind.opening),
      main: words(kind: SpeakKind.main),
      closing: words(kind: SpeakKind.closing),
    );
  }

  NaLabel kind({required SpeakKind kind}) => NaLabel(switch (kind) {
    SpeakKind.opening => l10n.openingSpeaker,
    SpeakKind.main => l10n.mainSpeaker,
    SpeakKind.closing => l10n.closingSpeaker,
  });

  NaLabel title({required Speak speak}) => NaLabel(switch (speak.title) {
    SpeakerTitle(:final name) => name.text,
    KindTitle(:final kind) => this.kind(kind: kind).value,
    EditionTitle(:final edition) => edition.text,
    ConventionTitle(:final label) => label.text,
  });

  NaLabel metaLine({required Speak speak}) =>
      _line(speak: speak, middle: speak.meta);

  NaLabel contextLine({required Speak speak}) =>
      _line(speak: speak, middle: speak.context);

  TrackTitle trackTitle({required Speak speak}) => TrackTitle(
    [
      title(speak: speak).value,
      ..._namedKind(speak: speak),
      ...speak.meta.map((part) => part.text),
    ].join(_separator),
  );

  NaLabel section({required SpeakConvention convention}) => NaLabel(
    [
      convention.label.text,
      ...switch (convention.city) {
        InCity(:final name) => [name.text],
        NoCity() => const <String>[],
      },
    ].join(_separator),
  );

  NaLabel language({required SpeakLanguage language}) =>
      NaLabel(switch (language) {
        SpeakLanguage.danish => l10n.languageDanish,
        SpeakLanguage.english => l10n.languageEnglish,
      });

  NaLabel _line({required Speak speak, required List<MetaPart> middle}) =>
      NaLabel(
        [
          ..._namedKind(speak: speak),
          ...middle.map((part) => part.text),
          ...switch (speak.language) {
            SpeakLanguage.english => [l10n.languageEnglish],
            SpeakLanguage.danish => const <String>[],
          },
        ].join(_separator),
      );

  List<String> _namedKind({required Speak speak}) =>
      switch ((speak.speaker, speak.kind)) {
        (NamedSpeaker(), KindOf(:final kind)) => [this.kind(kind: kind).value],
        (NamedSpeaker(), NoKind()) ||
        (NoSpeaker(), DetectedKind()) => const <String>[],
      };
}
