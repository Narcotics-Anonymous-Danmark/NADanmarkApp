import 'dart:convert';

import 'package:na_cli/src/boundary/field_text.dart';

sealed class JsonParse {
  const JsonParse();
}

final class JsonObjectParsed extends JsonParse {
  const JsonObjectParsed({required this.object});

  final JsonObject object;
}

final class JsonListParsed extends JsonParse {
  const JsonListParsed({required this.objects});

  final List<JsonObject> objects;
}

final class JsonMalformed extends JsonParse {
  const JsonMalformed({required this.reason});

  final String reason;
}

final class JsonObject {
  const JsonObject({required final Map<String, Object?> fields})
    : _fields = fields;

  const JsonObject.empty() : _fields = const {};

  final Map<String, Object?> _fields;

  static JsonParse parse({required final String text}) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) {
        return JsonObjectParsed(object: JsonObject(fields: decoded));
      }
      if (decoded is List<Object?>) {
        return JsonListParsed(objects: _objectsOf(decoded));
      }
      return const JsonMalformed(reason: 'expected a JSON object or list');
    } on FormatException catch (error) {
      return JsonMalformed(reason: error.message);
    }
  }

  static List<JsonObject> _objectsOf(final List<Object?> items) => items
      .whereType<Map<String, Object?>>()
      .map((final item) => JsonObject(fields: item))
      .toList(growable: false);

  List<String> get keys => _fields.keys.toList(growable: false);

  FieldText text({required final String key}) {
    final value = _fields[key];
    if (value is String) {
      return FieldPresent(value: value);
    }
    if (value is num) {
      return FieldPresent(value: value.toString());
    }
    return FieldAbsent(key: key);
  }

  FieldTruth truth({required final String key}) {
    final value = _fields[key];
    if (value is bool) {
      return value ? FieldTruth.yes : FieldTruth.no;
    }
    return FieldTruth.absent;
  }

  JsonObject object({required final String key}) {
    final value = _fields[key];
    if (value is Map<String, Object?>) {
      return JsonObject(fields: value);
    }
    return const JsonObject.empty();
  }

  List<JsonObject> objects({required final String key}) {
    final value = _fields[key];
    if (value is List<Object?>) {
      return _objectsOf(value);
    }
    return const [];
  }

  Map<String, String> get stringEntries => Map.unmodifiable({
    for (final entry in _fields.entries)
      if (entry.value is String) entry.key: entry.value.toString(),
  });
}
