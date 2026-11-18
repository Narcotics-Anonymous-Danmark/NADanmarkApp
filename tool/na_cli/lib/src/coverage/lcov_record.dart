extension type const SourceFile(String value) {}

extension type const LineNumber(int value) {}

extension type const HitCount(int value) {}

final class LcovRecord {
  const LcovRecord({required this.file, required this.hits});

  final SourceFile file;
  final Map<LineNumber, HitCount> hits;

  int get linesFound => hits.length;

  int get linesHit => hits.values.where((final hit) => hit.value > 0).length;

  LcovRecord mergedWith({required final LcovRecord other}) {
    final lines = {...hits.keys, ...other.hits.keys};
    return LcovRecord(
      file: file,
      hits: Map.unmodifiable({
        for (final line in lines)
          line: HitCount(
            (hits[line] ?? const HitCount(0)).value +
                (other.hits[line] ?? const HitCount(0)).value,
          ),
      }),
    );
  }

  LcovRecord relocated({required final SourceFile to}) =>
      LcovRecord(file: to, hits: hits);
}
