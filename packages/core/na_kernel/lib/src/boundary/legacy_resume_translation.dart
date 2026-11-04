import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/legacy_wire.dart';
import 'package:na_kernel/src/boundary/resume_codec.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/media/resume_point.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/values/storage_key.dart';

@immutable
final class LegacyResumeEntry {
  const LegacyResumeEntry({
    required this.kind,
    required this.id,
    required this.point,
  });

  final PlaylistKind kind;
  final PlaylistId id;
  final ResumePoint point;

  StorageKey get key => kind.pointKey(id: id);

  @override
  int get hashCode => Object.hash(kind, id, point);

  @override
  bool operator ==(Object other) =>
      other is LegacyResumeEntry &&
      other.kind == kind &&
      other.id == id &&
      other.point == point;

  @override
  String toString() => 'LegacyResumeEntry(${key.name}, $point)';
}

@immutable
final class LegacyResumeTranslation {
  const LegacyResumeTranslation({
    required this.entries,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final List<LegacyResumeEntry> entries;
  final List<StorageKey> importedKeys;
  final List<StorageKey> skippedKeys;

  ResumeIndex indexOf({required PlaylistKind kind}) => ResumeIndex(
    points: Map.unmodifiable(
      Map.fromEntries(
        entries
            .where((entry) => entry.kind == kind)
            .map((entry) => MapEntry(entry.id, entry.point)),
      ),
    ),
  );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(entries),
    Object.hashAll(importedKeys),
    Object.hashAll(skippedKeys),
  );

  @override
  bool operator ==(Object other) =>
      other is LegacyResumeTranslation &&
      other.entries.join(',') == entries.join(',') &&
      other.importedKeys.join(',') == importedKeys.join(',') &&
      other.skippedKeys.join(',') == skippedKeys.join(',');

  @override
  String toString() =>
      'LegacyResumeTranslation($entries, imported $importedKeys, '
      'skipped $skippedKeys)';
}

final class LegacyResumeTranslator {
  const LegacyResumeTranslator();

  static const ResumeCodec _codec = ResumeCodec();

  LegacyResumeTranslation translate({
    required LegacyStoreDumpDto dump,
    required Instant importedAt,
  }) {
    final read = (dump.mediaResume ?? const <String, ResumePointDto?>{}).entries
        .map(
          (entry) => _entryOf(
            key: entry.key,
            dto: entry.value,
            importedAt: importedAt,
          ),
        )
        .toList();
    return LegacyResumeTranslation(
      entries: List.unmodifiable(
        read.whereType<_Kept>().map((kept) => kept.entry),
      ),
      importedKeys: List.unmodifiable(
        read.whereType<_Kept>().map((kept) => kept.entry.key),
      ),
      skippedKeys: List.unmodifiable(
        read.whereType<_Dropped>().map((dropped) => dropped.key),
      ),
    );
  }

  _Read _entryOf({
    required String key,
    required ResumePointDto? dto,
    required Instant importedAt,
  }) {
    final kind = PlaylistKind.values.firstWhere(
      (kind) => key.startsWith(kind.pointKeyPrefix),
      orElse: () => PlaylistKind.book,
    );
    final id = PlaylistId(key.substring(kind.pointKeyPrefix.length));
    if (dto == null || id.value.isEmpty) {
      return _Dropped(key: StorageKey(key));
    }
    return switch (_codec.pointOf(dto: dto, fallbackTime: importedAt)) {
      Ok(value: final point) => _Kept(
        entry: LegacyResumeEntry(kind: kind, id: id, point: point),
      ),
      Err() => _Dropped(key: StorageKey(key)),
    };
  }
}

sealed class _Read {
  const _Read();
}

final class _Kept extends _Read {
  const _Kept({required this.entry});

  final LegacyResumeEntry entry;
}

final class _Dropped extends _Read {
  const _Dropped({required this.key});

  final StorageKey key;
}
