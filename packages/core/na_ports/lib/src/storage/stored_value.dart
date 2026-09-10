import 'package:meta/meta.dart';

@immutable
sealed class StoredValue {
  const StoredValue();
}

final class StoredString extends StoredValue {
  const StoredString({required this.value});

  final String value;

  @override
  int get hashCode => Object.hash(StoredString, value);

  @override
  bool operator ==(Object other) =>
      other is StoredString && other.value == value;

  @override
  String toString() => 'StoredString($value)';
}

final class NothingStored extends StoredValue {
  const NothingStored();

  @override
  int get hashCode => (NothingStored).hashCode;

  @override
  bool operator ==(Object other) => other is NothingStored;

  @override
  String toString() => 'NothingStored';
}
