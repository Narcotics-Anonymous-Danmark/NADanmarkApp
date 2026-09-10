import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/storage/stored_value.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class KeyValueStorePort {
  Future<StoredValue> read({required StorageKey key});

  Future<Outcome<StorageKey, StorageFailure>> write({
    required StorageKey key,
    required String value,
  });

  Future<Outcome<StorageKey, StorageFailure>> remove({
    required StorageKey key,
  });

  Future<List<StorageKey>> keysWithPrefix({required String prefix});
}

final Provider<KeyValueStorePort> keyValueStorePortProvider = unboundPort(
  portName: 'KeyValueStorePort',
);
