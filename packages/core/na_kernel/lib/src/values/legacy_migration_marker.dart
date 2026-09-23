import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/values/app_info.dart';

extension type const KeyCount(int value) {
  KeyCount operator +(KeyCount other) => KeyCount(value + other.value);
}

@immutable
final class LegacyMigrationMarker {
  const LegacyMigrationMarker({
    required this.appVersion,
    required this.completedAt,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final VersionName appVersion;
  final Instant completedAt;
  final KeyCount importedKeys;
  final KeyCount skippedKeys;

  @override
  int get hashCode =>
      Object.hash(appVersion, completedAt, importedKeys, skippedKeys);

  @override
  bool operator ==(Object other) =>
      other is LegacyMigrationMarker &&
      other.appVersion == appVersion &&
      other.completedAt == completedAt &&
      other.importedKeys == importedKeys &&
      other.skippedKeys == skippedKeys;

  @override
  String toString() =>
      'LegacyMigrationMarker($appVersion, $completedAt, '
      'imported: $importedKeys, skipped: $skippedKeys)';
}
