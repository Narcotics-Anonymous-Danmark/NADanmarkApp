@Tags(['unit'])
library;

import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_parser.dart';
import 'package:na_cli/src/coverage/lcov_path_rewriter.dart';
import 'package:na_cli/src/coverage/lcov_record.dart';
import 'package:na_cli/src/coverage/lcov_writer.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  const parser = LcovParser();

  test('parses SF and DA records', () {
    final doc = parser.parse(text: aLcovFile(hits: {1: 1, 2: 0, 3: 4}));
    expect(doc.records.single.file.value, 'lib/a.dart');
    expect(doc.records.single.linesFound, 3);
    expect(doc.records.single.linesHit, 2);
  });

  test('merges hits per file and line', () {
    final merged = LcovDocument.merge(
      documents: [
        parser.parse(text: aLcovFile(hits: {1: 1, 2: 0})),
        parser.parse(text: aLcovFile(hits: {2: 3, 5: 0})),
        parser.parse(
          text: aLcovFile(file: 'lib/b.dart', hits: {1: 0}),
        ),
      ],
    );
    expect(merged.records, hasLength(2));
    final a = merged.records.firstWhere(
      (final r) => r.file.value == 'lib/a.dart',
    );
    expect(a.hits[const LineNumber(2)], const HitCount(3));
    expect(a.linesFound, 3);
    expect(a.linesHit, 2);
    expect(merged.percent, closeTo(50, 0.01));
  });

  test('writes LF and LH from the hits', () {
    final text = const LcovWriter().write(
      document: parser.parse(text: aLcovFile(hits: {1: 1, 2: 0})),
    );
    expect(
      text,
      contains('SF:lib/a.dart\nDA:1,1\nDA:2,0\nLF:2\nLH:1\nend_of_record'),
    );
  });

  test('rewrites relative and absolute paths to repo-relative', () {
    const rewriter = LcovPathRewriter(repoRoot: FilePath('/repo'));
    final doc = parser.parse(
      text:
          '${aLcovFile()}'
          '${aLcovFile(file: '/repo/packages/core/na_kernel/lib/c.dart')}'
          '${aLcovFile(file: '/elsewhere/lib/d.dart')}',
    );
    final rewritten = rewriter.rewrite(
      document: doc,
      packageDirectory: const FilePath('/repo/packages/core/na_kernel'),
    );
    expect(rewritten.records.map((final r) => r.file.value), [
      'packages/core/na_kernel/lib/a.dart',
      'packages/core/na_kernel/lib/c.dart',
      '/elsewhere/lib/d.dart',
    ]);
  });

  test('empty document reports 100 percent', () {
    expect(const LcovDocument(records: []).percent, 100);
  });
}
