sealed class PlistValue {
  const PlistValue();

  PlistValue at({required String key}) => switch (this) {
    PlistDict(:final entries) => entries[key] ?? const PlistMissing(),
    PlistArray() ||
    PlistString() ||
    PlistDate() ||
    PlistData() ||
    PlistInteger() ||
    PlistBool() ||
    PlistMissing() => const PlistMissing(),
  };

  PlistValue index({required int position}) => switch (this) {
    PlistArray(:final items) =>
      position < items.length ? items[position] : const PlistMissing(),
    PlistDict() ||
    PlistString() ||
    PlistDate() ||
    PlistData() ||
    PlistInteger() ||
    PlistBool() ||
    PlistMissing() => const PlistMissing(),
  };

  String get text => switch (this) {
    PlistString(:final value) => value,
    PlistDate(:final value) => value.toIso8601String(),
    PlistInteger(:final value) => '$value',
    PlistBool(:final value) => value.name,
    PlistData(:final base64) => base64,
    PlistDict() || PlistArray() || PlistMissing() => '',
  };
}

final class PlistDict extends PlistValue {
  const PlistDict({required this.entries});

  final Map<String, PlistValue> entries;
}

final class PlistArray extends PlistValue {
  const PlistArray({required this.items});

  final List<PlistValue> items;
}

final class PlistString extends PlistValue {
  const PlistString({required this.value});

  final String value;
}

final class PlistDate extends PlistValue {
  const PlistDate({required this.value});

  final DateTime value;
}

final class PlistData extends PlistValue {
  const PlistData({required this.base64});

  final String base64;
}

final class PlistInteger extends PlistValue {
  const PlistInteger({required this.value});

  final int value;
}

enum PlistTruth { yes, no }

final class PlistBool extends PlistValue {
  const PlistBool({required this.value});

  final PlistTruth value;
}

final class PlistMissing extends PlistValue {
  const PlistMissing();
}
