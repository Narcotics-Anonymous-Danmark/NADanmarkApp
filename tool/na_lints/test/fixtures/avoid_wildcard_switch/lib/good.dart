enum Colour { red, green }

sealed class Shape {}

final class Circle extends Shape {}

final class Square extends Shape {}

String colourName({required final Colour colour}) => switch (colour) {
  Colour.red => 'red',
  Colour.green => 'green',
};

String shapeName({required final Shape shape}) => switch (shape) {
  Circle() => 'circle',
  Square() => 'square',
};

String sizeName({required final int size}) => switch (size) {
  0 => 'none',
  _ => 'some',
};

String textName({required final String text}) {
  switch (text) {
    case 'a':
      return 'first';
    default:
      return 'other';
  }
}
