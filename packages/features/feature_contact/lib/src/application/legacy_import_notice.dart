import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

enum ImportNotice { shown, hidden }

final FutureProvider<ImportNotice> legacyImportNoticeProvider = FutureProvider(
  (ref) async {
    final stored = await ref
        .read(keyValueStorePortProvider)
        .read(key: SettingKeys.legacyMigrationCompleted);
    return switch (stored) {
      StoredString(:final value) => switch (LegacyMigrationMarker.decode(
        text: value,
      )) {
        Ok(:final value) when value.importedKeys > 0 => ImportNotice.shown,
        Ok() || Err() => ImportNotice.hidden,
      },
      NothingStored() => ImportNotice.hidden,
    };
  },
);
