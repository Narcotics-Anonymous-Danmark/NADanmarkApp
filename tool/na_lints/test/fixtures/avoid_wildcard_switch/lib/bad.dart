enum Colour { red, green }

sealed class Shape {}

final class Circle extends Shape {}

final class Square extends Shape {}

String colourName({required final Colour colour}) {
  switch (colour) {
    case Colour.red:
      return 'red';
    // expect_lint: avoid_wildcard_switch
    default:
      return 'other';
  }
}

String shapeName({required final Shape shape}) => switch (shape) {
  Circle() => 'circle',
  // expect_lint: avoid_wildcard_switch
  _ => 'other',
};

void describe({required final Shape shape}) {
  switch (shape) {
    case Square():
      return;
    // expect_lint: avoid_wildcard_switch
    case _:
      return;
  }
}

String sizeName({required final int size}) => switch (size) {
  0 => 'none',
  // expect_lint: avoid_wildcard_switch
  _ => 'some',
};

String pairName({required final (Shape, Colour) pair}) => switch (pair) {
  // expect_lint: avoid_wildcard_switch
  (Circle(), _) => 'circle',
  (Square(), Colour.red) => 'red square',
  (Square(), Colour.green) => 'green square',
};

String typedName({required final Shape shape}) => switch (shape) {
  // expect_lint: avoid_wildcard_switch
  final Circle _ => 'circle',
  Square() => 'square',
};
