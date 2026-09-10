@Tags(['unit'])
library;

import 'package:adapter_storage/adapter_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _RefusingPlatform extends SharedPreferencesAsyncPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw Exception('disk full: ${invocation.memberName}');
}

void main() {
  group('storageOverrides', () {
    test('binds the key-value port to shared preferences', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(const {'firstday': 'mo'});
      final container = ProviderContainer(
        overrides: storageOverrides(preferences: SharedPreferencesAsync()),
      );
      addTearDown(container.dispose);
      expect(
        await container
            .read(keyValueStorePortProvider)
            .read(key: const StorageKey('firstday')),
        const StoredString(value: 'mo'),
      );
    });
  });

  group('SharedPreferencesStore failures', () {
    test('turns platform exceptions into storage failures', () async {
      SharedPreferencesAsyncPlatform.instance = _RefusingPlatform();
      final store = SharedPreferencesStore(
        preferences: SharedPreferencesAsync(),
      );
      final outcome = await store.write(
        key: const StorageKey('language'),
        value: 'da',
      );
      expect(outcome, isA<Err<StorageKey, StorageFailure>>());
    });
  });
}
