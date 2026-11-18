import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_record.dart';

final class LcovParser {
  const LcovParser();

  LcovDocument parse({required final String text}) {
    final blocks = text
        .split('end_of_record')
        .map((final block) => block.trim())
        .where((final block) => block.contains('SF:'));
    return LcovDocument(
      records: List.unmodifiable(blocks.map(_record)),
    );
  }

  LcovRecord _record(final String block) {
    final lines = block.split('\n').map((final line) => line.trim());
    final file = lines
        .firstWhere((final line) => line.startsWith('SF:'))
        .substring(3);
    final hits = lines
        .where((final line) => line.startsWith('DA:'))
        .map((final line) => line.substring(3).split(','))
        .where((final parts) => parts.length >= 2)
        .fold(<LineNumber, HitCount>{}, (final acc, final parts) {
          final line = LineNumber(int.parse(parts[0]));
          final count = HitCount(int.parse(parts[1]));
          return {
            ...acc,
            line: HitCount(
              (acc[line] ?? const HitCount(0)).value + count.value,
            ),
          };
        });
    return LcovRecord(file: SourceFile(file), hits: Map.unmodifiable(hits));
  }
}
