@Tags(['unit'])
library;

import 'package:na_cli/src/check/arb_parity.dart';
import 'package:test/test.dart';

String _pair(final MapEntry<String, String> e) => '"${e.key}": "${e.value}"';

void main() {
  ArbDocument arb(final Map<String, String> entries) =>
      (ArbDocument.parse(
                text: '{${entries.entries.map(_pair).join(',')}}',
              )
              as ArbParsed)
          .document;

  test('ignores metadata keys and reports parity', () {
    final report = const ArbParity().compare(
      english: arb({'@@locale': 'en', 'hello': 'Hello {name}', '@hello': 'x'}),
      danish: arb({'@@locale': 'da', 'hello': 'Hej {name}'}),
    );
    expect(report.verdict, ArbParityVerdict.inParity);
  });

  test('reports keys missing on either side and placeholder mismatches', () {
    final report = const ArbParity().compare(
      english: arb({'a': 'A', 'b': 'B {count}', 'c': 'C'}),
      danish: arb({'a': 'A', 'b': 'B', 'd': 'D'}),
    );
    expect(report.verdict, ArbParityVerdict.diverged);
    expect(report.missingInDanish, ['c']);
    expect(report.missingInEnglish, ['d']);
    expect(report.placeholderMismatches, ['b']);
    expect(report.problems, hasLength(3));
  });

  test('rejects invalid json', () {
    expect(ArbDocument.parse(text: '['), isA<ArbRejected>());
  });
}
