final class Counter {
  Counter({required this.start});

  final int start;

  // expect_lint: avoid_late
  late int current = start;

  // expect_lint: avoid_late
  late final String label;
}

int twice() {
  // expect_lint: avoid_late
  late final int value;
  value = 2;
  return value * 2;
}
