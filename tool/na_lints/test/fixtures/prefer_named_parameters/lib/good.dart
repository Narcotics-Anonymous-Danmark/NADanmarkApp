extension type const Km(double value) {}

final class Id {
  const Id(this.value);

  final int value;
}

final class Point {
  const Point({required this.x, required this.y});

  final int x;
  final int y;

  int manhattanTo({required final int otherX, required final int otherY}) =>
      (otherX - x).abs() + (otherY - y).abs();

  Point operator +(final Point other) => Point(x: x + other.x, y: y + other.y);
}

final class Always implements Pattern {
  const Always();

  @override
  Iterable<Match> allMatches(final String string, [final int start = 0]) =>
      const [];

  @override
  Match? matchAsPrefix(final String string, [final int start = 0]) => null;
}

void register({required final void Function(int a, int b) onChange}) {
  final combine = (final int a, final int b) => a + b;
  onChange(combine(1, 2), 3);
}

void main(final List<String> args, final String message) {}
