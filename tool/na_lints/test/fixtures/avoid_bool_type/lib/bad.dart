final class Flag {
  const Flag({required this.enabled});

  // expect_lint: avoid_bool_type
  final bool enabled;
}

// expect_lint: avoid_bool_type
bool isBlank({required final String text}) => text.trim().isEmpty;

void run({
  // expect_lint: avoid_bool_type
  required final bool Function(int value) predicate,
}) {}

void collect() {
  // expect_lint: avoid_bool_type
  final flags = <bool>[];
  flags.clear();
}
