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
  int() => 'some',
};

String pairName({required final (Shape, Colour) pair}) => switch (pair) {
  (Circle(), Colour()) => 'circle',
  (Square(), Colour.red) => 'red square',
  (Square(), Colour.green) => 'green square',
};

String valueName({required final Object? value}) => switch (value) {
  final String text => text,
  Object() => 'other',
  null => 'nothing',
};
