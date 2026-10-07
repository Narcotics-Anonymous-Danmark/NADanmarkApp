import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/meeting_formats.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/values/storage_key.dart';

enum SnapshotFreshness { fresh, stale }

abstract final class MeetingFormatKeys {
  static const StorageKey cache = StorageKey('meetingFormatsCache');
  static const StorageKey legacyCache = StorageKey('meeting_formats_v1');
}

@immutable
final class FormatsSnapshot {
  const FormatsSnapshot({required this.fetchedAt, required this.rows});

  static const Duration lifetime = Duration(days: 7);
  static const Duration retryAfterFailure = Duration(seconds: 60);

  final Instant fetchedAt;
  final List<FormatRow> rows;

  SnapshotFreshness freshnessAt({required Instant now}) =>
      now.since(other: fetchedAt) < lifetime
      ? SnapshotFreshness.fresh
      : SnapshotFreshness.stale;

  @override
  int get hashCode => Object.hash(fetchedAt, Object.hashAll(rows));

  @override
  bool operator ==(Object other) =>
      other is FormatsSnapshot &&
      other.fetchedAt == fetchedAt &&
      const ListEquality<FormatRow>().equals(other.rows, rows);

  @override
  String toString() => 'FormatsSnapshot($fetchedAt, ${rows.length} rows)';
}
