import 'dart:convert';

import 'package:na_kernel/src/boundary/legacy_wire.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/values/app_info.dart';
import 'package:na_kernel/src/values/legacy_migration_marker.dart';

final class MigrationMarkerCodec {
  const MigrationMarkerCodec();

  static const WireJson _wire = WireJson();

  String encode({required LegacyMigrationMarker marker}) => jsonEncode(
    MigrationMarkerDto(
      version: marker.appVersion.value,
      completedAt: marker.completedAt.utc.toIso8601String(),
      imported: marker.importedKeys.value,
      skipped: marker.skippedKeys.value,
    ).toJson(),
  );

  Outcome<LegacyMigrationMarker, DecodeFailure> decode({
    required String text,
  }) => _wire
      .parse(text: text, context: 'marker')
      .flatMap(
        transform: (json) => _wire.object(
          json: json,
          fromJson: MigrationMarkerDto.fromJson,
          context: 'marker',
        ),
      )
      .flatMap(transform: (dto) => markerOf(dto: dto));

  Outcome<LegacyMigrationMarker, DecodeFailure> markerOf({
    required MigrationMarkerDto dto,
  }) => switch ((
    dto.version,
    DateTime.tryParse(dto.completedAt ?? ''),
    dto.imported,
    dto.skipped,
  )) {
    (
      final String version,
      final DateTime completedAt,
      final int imported,
      final int skipped,
    ) =>
      Ok(
        value: LegacyMigrationMarker(
          appVersion: VersionName(version),
          completedAt: Instant(completedAt.toUtc()),
          importedKeys: KeyCount(imported),
          skippedKeys: KeyCount(skipped),
        ),
      ),
    _ => const Err(error: DecodeFailure(detail: 'marker: incomplete')),
  };
}
