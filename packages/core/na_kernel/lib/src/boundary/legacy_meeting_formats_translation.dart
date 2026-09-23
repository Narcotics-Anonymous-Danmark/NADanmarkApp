import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/bmlt_wire.dart';
import 'package:na_kernel/src/boundary/formats_cache_codec.dart';
import 'package:na_kernel/src/meetings/formats_snapshot.dart';
import 'package:na_kernel/src/results/outcome.dart';

@immutable
sealed class LegacyFormatsImport {
  const LegacyFormatsImport();
}

final class ImportFormatsCache extends LegacyFormatsImport {
  const ImportFormatsCache({required this.snapshot});

  final FormatsSnapshot snapshot;

  @override
  int get hashCode => Object.hash(ImportFormatsCache, snapshot);

  @override
  bool operator ==(Object other) =>
      other is ImportFormatsCache && other.snapshot == snapshot;

  @override
  String toString() => 'ImportFormatsCache($snapshot)';
}

final class SkipFormatsCache extends LegacyFormatsImport {
  const SkipFormatsCache();

  @override
  int get hashCode => (SkipFormatsCache).hashCode;

  @override
  bool operator ==(Object other) => other is SkipFormatsCache;

  @override
  String toString() => 'SkipFormatsCache';
}

final class LegacyMeetingFormatsTranslator {
  const LegacyMeetingFormatsTranslator();

  LegacyFormatsImport translate({required FormatsCacheDto cache}) =>
      switch (const FormatsCacheCodec().snapshotOf(dto: cache)) {
        Ok(:final value) when value.rows.isNotEmpty => ImportFormatsCache(
          snapshot: value,
        ),
        Ok() || Err() => const SkipFormatsCache(),
      };
}
