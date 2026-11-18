import 'package:collection/collection.dart';
import 'package:na_cli/src/coverage/lcov_record.dart';

enum RecordSelection { keep, drop }

final class LcovDocument {
  const LcovDocument({required this.records});

  factory LcovDocument.merge({required final List<LcovDocument> documents}) {
    final byFile = groupBy(
      documents.expand((final doc) => doc.records),
      (final record) => record.file,
    );
    final merged = byFile.values
        .map(
          (final records) => records.reduce(
            (final a, final b) => a.mergedWith(other: b),
          ),
        )
        .sortedBy((final record) => record.file.value);
    return LcovDocument(records: List.unmodifiable(merged));
  }

  final List<LcovRecord> records;

  int get linesFound => records.map((final r) => r.linesFound).sum;

  int get linesHit => records.map((final r) => r.linesHit).sum;

  double get percent => linesFound == 0 ? 100 : linesHit / linesFound * 100;

  LcovDocument select({
    required final RecordSelection Function(LcovRecord record) selection,
  }) => LcovDocument(
    records: List.unmodifiable(
      records.where(
        (final record) => selection(record) == RecordSelection.keep,
      ),
    ),
  );

  LcovDocument mapRecords({
    required final LcovRecord Function(LcovRecord record) transform,
  }) => LcovDocument(records: List.unmodifiable(records.map(transform)));
}
