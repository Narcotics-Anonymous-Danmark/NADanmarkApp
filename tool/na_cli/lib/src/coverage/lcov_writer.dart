import 'package:collection/collection.dart';
import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_record.dart';

final class LcovWriter {
  const LcovWriter();

  String write({required final LcovDocument document}) =>
      document.records.map(_record).join();

  String _record(final LcovRecord record) {
    final lines = record.hits.entries
        .sortedBy<num>((final entry) => entry.key.value)
        .map((final entry) => 'DA:${entry.key.value},${entry.value.value}');
    return [
      'SF:${record.file.value}',
      ...lines,
      'LF:${record.linesFound}',
      'LH:${record.linesHit}',
      'end_of_record',
      '',
    ].join('\n');
  }
}
