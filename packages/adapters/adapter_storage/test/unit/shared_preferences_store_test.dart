@Tags(['unit'])
library;

import 'package:adapter_storage/adapter_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

SharedPreferencesStore aStore({Map<String, Object> seeded = const {}}) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(seeded);
  return SharedPreferencesStore(preferences: SharedPreferencesAsync());
}

void main() {
  group('SharedPreferencesStore', () {
    test('reads a stored string', () async {
      final store = aStore(seeded: const {'language': 'en'});
      expect(
        await store.read(key: const StorageKey('language')),
        const StoredString(value: 'en'),
      );
    });

    test('reports nothing stored for an unknown key', () async {
      expect(
        await aStore().read(key: const StorageKey('missing')),
        const NothingStored(),
      );
    });

    test('writes, lists by prefix and removes', () async {
      final store = aStore();
      await store.write(
        key: const StorageKey('mediaResume.book.a'),
        value: '1',
      );
      await store.write(key: const StorageKey('other'), value: '2');
      expect(
        await store.keysWithPrefix(prefix: 'mediaResume.'),
        [const StorageKey('mediaResume.book.a')],
      );
      expect(
        await store.remove(key: const StorageKey('other')),
        const Ok<StorageKey, StorageFailure>(value: StorageKey('other')),
      );
      expect(
        await store.read(key: const StorageKey('other')),
        const NothingStored(),
      );
    });
  });
}
