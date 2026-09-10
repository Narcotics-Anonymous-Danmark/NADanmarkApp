import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class KeyValueSettingsStore implements SettingsPort {
  const KeyValueSettingsStore({required this.store});

  final KeyValueStorePort store;

  static const SettingsCodec _codec = SettingsCodec();

  @override
  Future<Settings> read() async {
    final stored = <StorageKey, String>{};
    for (final key in SettingKeys.all) {
      switch (await store.read(key: key)) {
        case StoredString(:final value):
          stored[key] = value;
        case NothingStored():
          break;
      }
    }
    return _codec.decode(stored: stored);
  }

  @override
  Future<Outcome<Settings, StorageFailure>> write({
    required Settings settings,
  }) async {
    for (final entry in _codec.encode(settings: settings).entries) {
      switch (await store.write(key: entry.key, value: entry.value)) {
        case Ok():
          continue;
        case Err(:final error):
          return Err(error: error);
      }
    }
    return Ok(value: settings);
  }
}
