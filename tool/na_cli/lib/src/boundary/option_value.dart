sealed class OptionValue {
  const OptionValue();

  String orElse({required String fallback}) => switch (this) {
    OptionGiven(:final value) => value,
    OptionOmitted() => fallback,
  };
}

final class OptionGiven extends OptionValue {
  const OptionGiven({required this.value});

  final String value;
}

final class OptionOmitted extends OptionValue {
  const OptionOmitted();
}

enum FlagState { on, off }
