import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class KeyValueStoreMimic implements KeyValueStorePort {
  KeyValueStoreMimic({required Map<String, String> seeded})
    : _values = Map.of(seeded);

  factory KeyValueStoreMimic.empty() => KeyValueStoreMimic(seeded: const {});

  final Map<String, String> _values;
  final List<StorageKey> writes = [];
  final List<StorageKey> removals = [];
  WriteBehaviour behaviour = WriteBehaviour.succeed;

  Map<String, String> get snapshot => Map.unmodifiable(_values);

  @override
  Future<StoredValue> read({required StorageKey key}) async =>
      switch (_values[key.name]) {
        final String value => StoredString(value: value),
        null => const NothingStored(),
      };

  @override
  Future<Outcome<StorageKey, StorageFailure>> write({
    required StorageKey key,
    required String value,
  }) async {
    writes.add(key);
    return switch (behaviour) {
      WriteBehaviour.succeed => _store(key: key, value: value),
      WriteBehaviour.fail => Err(
        error: StorageFailure(detail: 'mimic refused to write ${key.name}'),
      ),
    };
  }

  @override
  Future<Outcome<StorageKey, StorageFailure>> remove({
    required StorageKey key,
  }) async {
    removals.add(key);
    _values.remove(key.name);
    return Ok(value: key);
  }

  @override
  Future<List<StorageKey>> keysWithPrefix({required String prefix}) async =>
      List.unmodifiable(
        _values.keys
            .where((name) => name.startsWith(prefix))
            .map(StorageKey.new),
      );

  Outcome<StorageKey, StorageFailure> _store({
    required StorageKey key,
    required String value,
  }) {
    _values[key.name] = value;
    return Ok(value: key);
  }
}

enum WriteBehaviour { succeed, fail }
