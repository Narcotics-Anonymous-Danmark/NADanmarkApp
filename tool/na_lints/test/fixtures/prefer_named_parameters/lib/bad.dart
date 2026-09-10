final class Point {
  // expect_lint: prefer_named_parameters
  const Point(this.x, this.y);

  final int x;
  final int y;

  // expect_lint: prefer_named_parameters
  int manhattanTo(final int otherX, final int otherY) =>
      (otherX - x).abs() + (otherY - y).abs();
}

// expect_lint: prefer_named_parameters
int add(final int a, [final int b = 0]) => a + b;

// expect_lint: prefer_named_parameters
void log(final String message, final Object context) {}
