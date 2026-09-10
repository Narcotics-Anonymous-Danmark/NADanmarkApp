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

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('reads defaults, writes every key and reads them back', () async {
    final store = KeyValueSettingsStore(
      store: SharedPreferencesStore(preferences: SharedPreferencesAsync()),
    );
    expect(await store.read(), Settings.defaults);
    const changed = Settings(
      language: Language.english,
      firstDayOfWeek: FirstDayOfWeek.sunday,
      cleanTimeUnitOrder: CleanTimeUnitOrder.daysMonthsYears,
      searchRadius: Km(30),
    );
    expect(
      await store.write(settings: changed),
      const Ok<Settings, StorageFailure>(value: changed),
    );
    expect(await SharedPreferencesAsync().getString('firstday'), 'su');
    expect(await store.read(), changed);
  });

  test('malformed stored values fall back to the defaults', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString('searchRange', 'abc');
    await preferences.setString('language', 'en');
    final store = KeyValueSettingsStore(
      store: SharedPreferencesStore(preferences: preferences),
    );
    final settings = await store.read();
    expect(settings.searchRadius, const Km(15));
    expect(settings.language, Language.english);
  });

  test('storageOverrides binds both storage ports', () {
    final container = ProviderContainer(
      overrides: storageOverrides(preferences: SharedPreferencesAsync()),
    );
    addTearDown(container.dispose);
    expect(container.read(settingsPortProvider), isA<KeyValueSettingsStore>());
    expect(
      container.read(keyValueStorePortProvider),
      isA<SharedPreferencesStore>(),
    );
  });
}
