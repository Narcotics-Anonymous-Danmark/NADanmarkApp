import 'package:collection/collection.dart';
import 'package:na_cli/src/boundary/json_object.dart';

final class ArbDocument {
  const ArbDocument({required this.messages});

  final Map<String, String> messages;

  static final RegExp _placeholder = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  static ArbParse parse({required final String text}) =>
      switch (JsonObject.parse(text: text)) {
        JsonObjectParsed(:final object) => ArbParsed(
          document: ArbDocument(
            messages: Map.unmodifiable({
              for (final entry in object.stringEntries.entries)
                if (!entry.key.startsWith('@')) entry.key: entry.value,
            }),
          ),
        ),
        JsonListParsed() => const ArbRejected(reason: 'ARB must be an object'),
        JsonMalformed(:final reason) => ArbRejected(reason: reason),
      };

  Set<String> get keys => messages.keys.toSet();

  Set<String> placeholdersOf({required final String key}) => _placeholder
      .allMatches(messages[key] ?? '')
      .map((final match) => match.group(1).toString())
      .toSet();
}

final class ArbParity {
  const ArbParity();

  ArbParityReport compare({
    required final ArbDocument english,
    required final ArbDocument danish,
  }) {
    final shared = english.keys.intersection(danish.keys).sorted();
    return ArbParityReport(
      missingInDanish: List.unmodifiable(
        english.keys.difference(danish.keys).sorted(),
      ),
      missingInEnglish: List.unmodifiable(
        danish.keys.difference(english.keys).sorted(),
      ),
      placeholderMismatches: List.unmodifiable(
        shared.where(
          (final key) => !const SetEquality<String>().equals(
            english.placeholdersOf(key: key),
            danish.placeholdersOf(key: key),
          ),
        ),
      ),
    );
  }
}

final class ArbParityReport {
  const ArbParityReport({
    required this.missingInDanish,
    required this.missingInEnglish,
    required this.placeholderMismatches,
  });

  final List<String> missingInDanish;
  final List<String> missingInEnglish;
  final List<String> placeholderMismatches;

  ArbParityVerdict get verdict =>
      missingInDanish.isEmpty &&
          missingInEnglish.isEmpty &&
          placeholderMismatches.isEmpty
      ? ArbParityVerdict.inParity
      : ArbParityVerdict.diverged;

  List<String> get problems => [
    ...missingInDanish.map((final key) => 'missing in app_da.arb: $key'),
    ...missingInEnglish.map((final key) => 'missing in app_en.arb: $key'),
    ...placeholderMismatches.map((final key) => 'placeholders differ: $key'),
  ];
}

enum ArbParityVerdict { inParity, diverged }

sealed class ArbParse {
  const ArbParse();
}

final class ArbParsed extends ArbParse {
  const ArbParsed({required this.document});

  final ArbDocument document;
}

final class ArbRejected extends ArbParse {
  const ArbRejected({required this.reason});

  final String reason;
}
