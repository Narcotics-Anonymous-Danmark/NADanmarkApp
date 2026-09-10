import 'package:meta/meta.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

@immutable
sealed class LoadResult<T> {
  const LoadResult();

  static LoadResult<T> fromOutcome<T>({
    required Outcome<T, Failure> outcome,
  }) => switch (outcome) {
    Ok(:final value) => Loaded(value: value),
    Err(:final error) => Failed(failure: error),
  };

  LoadResult<R> map<R>({required R Function(T value) transform}) =>
      switch (this) {
        Loading() => Loading<R>(),
        Loaded(:final value) => Loaded(value: transform(value)),
        Failed(:final failure) => Failed(failure: failure),
      };
}

final class Loading<T> extends LoadResult<T> {
  const Loading();

  @override
  int get hashCode => (Loading).hashCode;

  @override
  bool operator ==(Object other) => other is Loading<T>;

  @override
  String toString() => 'Loading';
}

final class Loaded<T> extends LoadResult<T> {
  const Loaded({required this.value});

  final T value;

  @override
  int get hashCode => Object.hash(Loaded, value);

  @override
  bool operator ==(Object other) => other is Loaded<T> && other.value == value;

  @override
  String toString() => 'Loaded($value)';
}

final class Failed<T> extends LoadResult<T> {
  const Failed({required this.failure});

  final Failure failure;

  @override
  int get hashCode => Object.hash(Failed, failure);

  @override
  bool operator ==(Object other) =>
      other is Failed<T> && other.failure == failure;

  @override
  String toString() => 'Failed($failure)';
}
