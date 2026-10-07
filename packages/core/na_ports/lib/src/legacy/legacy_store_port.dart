import 'package:meta/meta.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class LegacyStoreRead {
  const LegacyStoreRead();
}

final class LegacyStoreFound extends LegacyStoreRead {
  const LegacyStoreFound({required this.dump});

  final LegacyStoreDumpDto dump;

  @override
  int get hashCode => Object.hash(LegacyStoreFound, dump);

  @override
  bool operator ==(Object other) =>
      other is LegacyStoreFound && other.dump == dump;

  @override
  String toString() => 'LegacyStoreFound($dump)';
}

final class LegacyStoreAbsent extends LegacyStoreRead {
  const LegacyStoreAbsent();

  @override
  int get hashCode => (LegacyStoreAbsent).hashCode;

  @override
  bool operator ==(Object other) => other is LegacyStoreAbsent;

  @override
  String toString() => 'LegacyStoreAbsent';
}

final class LegacyStoreUnreadable extends LegacyStoreRead {
  const LegacyStoreUnreadable({required this.detail});

  final String detail;

  @override
  int get hashCode => Object.hash(LegacyStoreUnreadable, detail);

  @override
  bool operator ==(Object other) =>
      other is LegacyStoreUnreadable && other.detail == detail;

  @override
  String toString() => 'LegacyStoreUnreadable($detail)';
}

abstract interface class LegacyStorePort {
  Future<LegacyStoreRead> readAll();
}

final Provider<LegacyStorePort> legacyStorePortProvider = unboundPort(
  portName: 'LegacyStorePort',
);
