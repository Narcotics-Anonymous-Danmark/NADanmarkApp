import 'package:meta/meta.dart';

@immutable
sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required this.detail});

  final String detail;

  @override
  int get hashCode => Object.hash(NetworkFailure, detail);

  @override
  bool operator ==(Object other) =>
      other is NetworkFailure && other.detail == detail;

  @override
  String toString() => 'NetworkFailure($detail)';
}

final class DecodeFailure extends Failure {
  const DecodeFailure({required this.detail});

  final String detail;

  @override
  int get hashCode => Object.hash(DecodeFailure, detail);

  @override
  bool operator ==(Object other) =>
      other is DecodeFailure && other.detail == detail;

  @override
  String toString() => 'DecodeFailure($detail)';
}

final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure();

  @override
  int get hashCode => (PermissionDeniedFailure).hashCode;

  @override
  bool operator ==(Object other) => other is PermissionDeniedFailure;

  @override
  String toString() => 'PermissionDeniedFailure';
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({required this.after});

  final Duration after;

  @override
  int get hashCode => Object.hash(TimeoutFailure, after);

  @override
  bool operator ==(Object other) =>
      other is TimeoutFailure && other.after == after;

  @override
  String toString() => 'TimeoutFailure($after)';
}

final class StorageFailure extends Failure {
  const StorageFailure({required this.detail});

  final String detail;

  @override
  int get hashCode => Object.hash(StorageFailure, detail);

  @override
  bool operator ==(Object other) =>
      other is StorageFailure && other.detail == detail;

  @override
  String toString() => 'StorageFailure($detail)';
}

final class UnavailableFailure extends Failure {
  const UnavailableFailure({required this.what});

  final String what;

  @override
  int get hashCode => Object.hash(UnavailableFailure, what);

  @override
  bool operator ==(Object other) =>
      other is UnavailableFailure && other.what == what;

  @override
  String toString() => 'UnavailableFailure($what)';
}
