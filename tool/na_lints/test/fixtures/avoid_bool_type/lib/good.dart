enum Enabled { on, off }

Iterable<int> evens({required final List<int> values}) =>
    values.where((final value) => value.isEven);

String kind({required final Object value}) => value is bool ? 'flag' : 'other';

final class Id {
  const Id({required this.value});

  final int value;

  @override
  bool operator ==(final Object other) => other is Id && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
