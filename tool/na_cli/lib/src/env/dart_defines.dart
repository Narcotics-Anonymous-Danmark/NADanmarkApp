import 'package:na_cli/src/boundary/json_object.dart';

final class DartDefines {
  const DartDefines({required this.values});

  final Map<String, String> values;

  static DartDefinesParse parse({required final String json}) =>
      switch (JsonObject.parse(text: json)) {
        JsonObjectParsed(:final object) => DartDefinesParsed(
          defines: DartDefines(values: object.stringEntries),
        ),
        JsonListParsed() => const DartDefinesRejected(
          reason: 'env file must be a JSON object',
        ),
        JsonMalformed(:final reason) => DartDefinesRejected(reason: reason),
      };

  String valueOf({required final String key}) => values[key] ?? '';

  Map<String, String> get childEnvironment => Map.unmodifiable({
    if (valueOf(key: 'GOOGLE_MAPS_API_KEY').isNotEmpty)
      'GOOGLE_MAPS_API_KEY': valueOf(key: 'GOOGLE_MAPS_API_KEY'),
  });

  List<String> missingNonEmpty({required final List<String> keys}) =>
      List.unmodifiable(
        keys.where((final key) => valueOf(key: key).trim().isEmpty),
      );
}

sealed class DartDefinesParse {
  const DartDefinesParse();
}

final class DartDefinesParsed extends DartDefinesParse {
  const DartDefinesParsed({required this.defines});

  final DartDefines defines;
}

final class DartDefinesRejected extends DartDefinesParse {
  const DartDefinesRejected({required this.reason});

  final String reason;
}
