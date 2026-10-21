import 'package:meta/meta.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final Provider<CleantimeProfilesStore> cleantimeProfilesStoreProvider =
    Provider(
      (ref) => CleantimeProfilesStore(
        storage: ref.read(keyValueStorePortProvider),
      ),
    );

@immutable
sealed class StoredProfiles {
  const StoredProfiles();
}

final class ProfilesFound extends StoredProfiles {
  const ProfilesFound({required this.entries, required this.active});

  final List<CleantimeProfile> entries;
  final ProfileIndex active;
}

final class NoProfiles extends StoredProfiles {
  const NoProfiles();
}

final class CleantimeProfilesStore {
  const CleantimeProfilesStore({required this.storage});

  static const CleantimeProfilesCodec _codec = CleantimeProfilesCodec();

  final KeyValueStorePort storage;

  Future<StoredProfiles> load() async {
    final profiles = switch (await storage.read(
      key: SettingKeys.cleantimeProfiles,
    )) {
      StoredString(:final value) =>
        _codec
            .decodeProfiles(text: value)
            .fold(
              onOk: (entries) => entries,
              onErr: (_) => <CleantimeProfile>[],
            ),
      NothingStored() => const <CleantimeProfile>[],
    };
    if (profiles.isEmpty) {
      return const NoProfiles();
    }
    final active = switch (await storage.read(
      key: SettingKeys.activeCleantimeProfile,
    )) {
      StoredString(:final value) =>
        _codec
            .decodeActive(text: value)
            .fold(
              onOk: (index) => index,
              onErr: (_) => const ProfileIndex(0),
            ),
      NothingStored() => const ProfileIndex(0),
    };
    return ProfilesFound(
      entries: profiles,
      active: active.within(entries: profiles),
    );
  }

  Future<Outcome<StorageKey, StorageFailure>> save({
    required CleantimeProfiles profiles,
  }) async {
    final written = await storage.write(
      key: SettingKeys.cleantimeProfiles,
      value: _codec.encodeProfiles(profiles: profiles.entries),
    );
    return switch (written) {
      Ok() => storage.write(
        key: SettingKeys.activeCleantimeProfile,
        value: _codec.encodeActive(index: profiles.active),
      ),
      Err() => written,
    };
  }
}
