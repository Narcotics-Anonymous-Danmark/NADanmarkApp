import 'package:na_cli/src/ports/environment.dart';

sealed class EnvValue {
  const EnvValue();

  String orElse({required String fallback}) => switch (this) {
    EnvSet(:final value) => value,
    EnvUnset() => fallback,
  };
}

final class EnvSet extends EnvValue {
  const EnvSet({required this.value});

  final String value;
}

final class EnvUnset extends EnvValue {
  const EnvUnset({required this.key});

  final EnvKey key;
}
