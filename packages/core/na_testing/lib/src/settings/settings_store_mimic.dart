import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/storage/key_value_store_mimic.dart';

final class SettingsStoreMimic implements SettingsPort {
  const SettingsStoreMimic({required this.storage});

  final KeyValueStoreMimic storage;

  static const SettingsCodec _codec = SettingsCodec();

  @override
  Future<Settings> read() async {
    final stored = <StorageKey, String>{};
    for (final key in SettingKeys.all) {
      switch (await storage.read(key: key)) {
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
      switch (await storage.write(key: entry.key, value: entry.value)) {
        case Ok():
          continue;
        case Err(:final error):
          return Err(error: error);
      }
    }
    return Ok(value: settings);
  }
}
