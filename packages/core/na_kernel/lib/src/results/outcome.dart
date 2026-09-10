import 'package:meta/meta.dart';

@immutable
sealed class Outcome<T, F> {
  const Outcome();

  Outcome<R, F> map<R>({required R Function(T value) transform}) =>
      switch (this) {
        Ok(:final value) => Ok(value: transform(value)),
        Err(:final error) => Err(error: error),
      };

  Outcome<R, F> flatMap<R>({
    required Outcome<R, F> Function(T value) transform,
  }) => switch (this) {
    Ok(:final value) => transform(value),
    Err(:final error) => Err(error: error),
  };

  R fold<R>({
    required R Function(T value) onOk,
    required R Function(F error) onErr,
  }) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final error) => onErr(error),
  };
}

final class Ok<T, F> extends Outcome<T, F> {
  const Ok({required this.value});

  final T value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  bool operator ==(Object other) => other is Ok<T, F> && other.value == value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, F> extends Outcome<T, F> {
  const Err({required this.error});

  final F error;

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  bool operator ==(Object other) => other is Err<T, F> && other.error == error;

  @override
  String toString() => 'Err($error)';
}
