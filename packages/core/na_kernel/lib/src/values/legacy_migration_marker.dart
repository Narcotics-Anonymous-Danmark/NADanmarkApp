import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/json_reader.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/instant.dart';

@immutable
final class LegacyMigrationMarker {
  const LegacyMigrationMarker({
    required this.appVersion,
    required this.completedAt,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final String appVersion;
  final Instant completedAt;
  final int importedKeys;
  final int skippedKeys;

  String get encoded => jsonEncode({
    'version': appVersion,
    'completedAt': completedAt.utc.toIso8601String(),
    'imported': importedKeys,
    'skipped': skippedKeys,
  });

  static Outcome<LegacyMigrationMarker, DecodeFailure> decode({
    required String text,
  }) {
    try {
      final decoded = jsonDecode(text);
      return switch (decoded) {
        final JsonMap map => _fromReader(
          reader: JsonReader(json: map, context: 'marker'),
        ),
        final Object other => Err(
          error: DecodeFailure(detail: 'marker: not an object ($other)'),
        ),
        null => const Err(error: DecodeFailure(detail: 'marker: null')),
      };
    } on FormatException catch (error) {
      return Err(error: DecodeFailure(detail: 'marker: ${error.message}'));
    }
  }

  static Outcome<LegacyMigrationMarker, DecodeFailure> _fromReader({
    required JsonReader reader,
  }) => reader
      .string(key: 'version')
      .flatMap(
        transform: (version) => reader
            .string(key: 'completedAt')
            .flatMap(
              transform: (completedAt) => reader
                  .integer(key: 'imported')
                  .flatMap(
                    transform: (imported) => reader
                        .integer(key: 'skipped')
                        .flatMap(
                          transform: (skipped) =>
                              switch (DateTime.tryParse(completedAt)) {
                                final DateTime parsed => Ok(
                                  value: LegacyMigrationMarker(
                                    appVersion: version,
                                    completedAt: Instant(parsed.toUtc()),
                                    importedKeys: imported,
                                    skippedKeys: skipped,
                                  ),
                                ),
                                null => const Err(
                                  error: DecodeFailure(
                                    detail: 'marker.completedAt: not a date',
                                  ),
                                ),
                              },
                        ),
                  ),
            ),
      );

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
