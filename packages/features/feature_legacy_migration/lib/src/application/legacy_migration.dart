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

  final KeyCount importedKeys;
  final KeyCount skippedKeys;
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
  static const LegacyMeetingFormatsTranslator _formatsTranslator =
      LegacyMeetingFormatsTranslator();

  Future<MigrationRun> runIfNeeded() async {
    switch (await store.read(key: SettingKeys.legacyMigrationCompleted)) {
      case StoredString():
        return const MigrationAlreadyDone();
      case NothingStored():
        break;
    }
    final read = await legacyStore.readAll();
    final translation = switch (read) {
      LegacyStoreFound(:final dump) => _translator.translate(dump: dump),
      LegacyStoreAbsent() || LegacyStoreUnreadable() => _translator.translate(
        dump: const LegacyStoreDumpDto(),
      ),
    };
    await _importSettings(translation: translation);
    final formats = await _importFormatsCache(read: read);
    final marker = LegacyMigrationMarker(
      appVersion: appInfo.version,
      completedAt: clock.now(),
      importedKeys:
          KeyCount(translation.importedKeys.length) + formats.imported,
      skippedKeys: KeyCount(translation.skippedKeys.length) + formats.skipped,
    );
    await store.write(
      key: SettingKeys.legacyMigrationCompleted,
      value: const MigrationMarkerCodec().encode(marker: marker),
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

  Future<({KeyCount imported, KeyCount skipped})> _importFormatsCache({
    required LegacyStoreRead read,
  }) async {
    final cache = switch (read) {
      LegacyStoreFound(:final dump) => dump.meetingFormatsV1,
      LegacyStoreAbsent() || LegacyStoreUnreadable() => null,
    };
    if (cache == null) {
      return (imported: const KeyCount(0), skipped: const KeyCount(0));
    }
    switch (_formatsTranslator.translate(cache: cache)) {
      case ImportFormatsCache(:final snapshot):
        switch (await store.read(key: MeetingFormatKeys.cache)) {
          case StoredString():
            break;
          case NothingStored():
            await store.write(
              key: MeetingFormatKeys.cache,
              value: const FormatsCacheCodec().encode(snapshot: snapshot),
            );
        }
        return (imported: const KeyCount(1), skipped: const KeyCount(0));
      case SkipFormatsCache():
        return (imported: const KeyCount(0), skipped: const KeyCount(1));
    }
  }

  Future<void> _importSettings({
    required LegacySettingsTranslation translation,
  }) async {
    final values = translation.settings.stored;
    for (final key in translation.importedKeys) {
      switch (await store.read(key: key)) {
        case StoredString():
          continue;
        case NothingStored():
          await store.write(key: key, value: values[key] ?? '');
      }
    }
  }
}
