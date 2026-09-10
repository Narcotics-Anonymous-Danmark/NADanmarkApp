import 'package:adapter_storage/src/key_value_settings_store.dart';
import 'package:adapter_storage/src/shared_preferences_store.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Override> storageOverrides({
  required SharedPreferencesAsync preferences,
}) {
  final store = SharedPreferencesStore(preferences: preferences);
  return [
    keyValueStorePortProvider.overrideWithValue(store),
    settingsPortProvider.overrideWithValue(KeyValueSettingsStore(store: store)),
  ];
}
