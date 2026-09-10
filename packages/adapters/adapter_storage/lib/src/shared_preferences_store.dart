import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesStore implements KeyValueStorePort {
  const SharedPreferencesStore({required this.preferences});

  final SharedPreferencesAsync preferences;

  @override
  Future<StoredValue> read({required StorageKey key}) async => bridgeNullable(
    value: await preferences.getString(key.name),
    whenPresent: (value) => StoredString(value: value),
    whenAbsent: () => const NothingStored(),
  );

  @override
  Future<Outcome<StorageKey, StorageFailure>> write({
    required StorageKey key,
    required String value,
  }) => _guard(key: key, action: () => preferences.setString(key.name, value));

  @override
  Future<Outcome<StorageKey, StorageFailure>> remove({
    required StorageKey key,
  }) => _guard(key: key, action: () => preferences.remove(key.name));

  @override
  Future<List<StorageKey>> keysWithPrefix({required String prefix}) async {
    final keys = await preferences.getKeys();
    return List.unmodifiable(
      keys.where((name) => name.startsWith(prefix)).map(StorageKey.new),
    );
  }

  Future<Outcome<StorageKey, StorageFailure>> _guard({
    required StorageKey key,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
      return Ok(value: key);
    } on Exception catch (error) {
      return Err(error: StorageFailure(detail: '${key.name}: $error'));
    }
  }
}
