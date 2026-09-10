sealed class FieldText {
  const FieldText();

  String orElse({required String fallback}) => switch (this) {
    FieldPresent(:final value) => value,
    FieldAbsent() => fallback,
  };
}

final class FieldPresent extends FieldText {
  const FieldPresent({required this.value});

  final String value;
}

final class FieldAbsent extends FieldText {
  const FieldAbsent({required this.key});

  final String key;
}

enum FieldTruth { yes, no, absent }
