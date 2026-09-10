import 'package:meta/meta.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class MigrationRun {
  const MigrationRun();
}

final class MigrationAlreadyDone extends MigrationRun {
  const MigrationAlreadyDone();

  @override
  int get hashCode => (MigrationAlreadyDone).hashCode;

  @override
  bool operator ==(Object other) => other is MigrationAlreadyDone;
}

final class MigrationRan extends MigrationRun {
  const MigrationRan({
    required this.importedKeys,
    required this.skippedKeys,
    required this.source,
  });

  final int importedKeys;
  final int skippedKeys;
  final LegacyStoreRead source;

  @override
  int get hashCode => Object.hash(importedKeys, skippedKeys, source);

  @override
  bool operator ==(Object other) =>
      other is MigrationRan &&
      other.importedKeys == importedKeys &&
      other.skippedKeys == skippedKeys &&
      other.source == source;

  @override
  String toString() =>
      'MigrationRan(imported: $importedKeys, skipped: $skippedKeys, $source)';
}

final Provider<LegacyMigration> legacyMigrationProvider = Provider(
  (ref) => LegacyMigration(
    store: ref.watch(keyValueStorePortProvider),
    legacyStore: ref.watch(legacyStorePortProvider),
    clock: ref.watch(clockProvider),
    appInfo: ref.watch(appInfoProvider),
    events: ref.watch(eventBusProvider),
  ),
);

final class LegacyMigration {
  const LegacyMigration({
    required this.store,
    required this.legacyStore,
    required this.clock,
    required this.appInfo,
    required this.events,
  });

  final KeyValueStorePort store;
  final LegacyStorePort legacyStore;
  final Clock clock;
  final AppInfo appInfo;
  final EventBus events;

  static const LegacySettingsTranslator _translator =
      LegacySettingsTranslator();

  Future<MigrationRun> runIfNeeded() async {
    switch (await store.read(key: SettingKeys.legacyMigrationCompleted)) {
      case StoredString():
        return const MigrationAlreadyDone();
      case NothingStored():
        break;
    }
    final read = await legacyStore.readAll();
    final translation = switch (read) {
      LegacyStoreFound(:final entries) => _translator.translate(
        entries: entries,
      ),
      LegacyStoreAbsent() || LegacyStoreUnreadable() => _translator.translate(
        entries: const {},
      ),
    };
    await _importSettings(translation: translation);
    final marker = LegacyMigrationMarker(
      appVersion: appInfo.version,
      completedAt: clock.now(),
      importedKeys: translation.importedKeys.length,
      skippedKeys: translation.skippedKeys.length,
    );
    await store.write(
      key: SettingKeys.legacyMigrationCompleted,
      value: marker.encoded,
    );
    events.publish(
      event: LegacyMigrationCompleted(
        importedKeys: marker.importedKeys,
        skippedKeys: marker.skippedKeys,
      ),
    );
    return MigrationRan(
      importedKeys: marker.importedKeys,
      skippedKeys: marker.skippedKeys,
      source: read,
    );
  }

  Future<void> _importSettings({
    required LegacySettingsTranslation translation,
  }) async {
    final values = translation.settings.stored;
    for (final name in translation.importedKeys) {
      final key = StorageKey(name);
      switch (await store.read(key: key)) {
        case StoredString():
          continue;
        case NothingStored():
          await store.write(key: key, value: values[key] ?? '');
      }
    }
  }
}
