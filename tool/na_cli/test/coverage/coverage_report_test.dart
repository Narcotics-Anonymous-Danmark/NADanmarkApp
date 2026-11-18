@Tags(['unit'])
library;

import 'package:na_cli/src/coverage/coverage_markdown.dart';
import 'package:na_cli/src/coverage/coverage_policy.dart';
import 'package:na_cli/src/coverage/coverage_report.dart';
import 'package:na_cli/src/coverage/glob_pattern.dart';
import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_parser.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

const String kernel = 'packages/core/na_kernel/lib';
const String feature = 'packages/features/feature_meetings/lib';
const String adapter = 'packages/adapters/adapter_bmlt/lib';
const Map<int, int> kernelHits = {1: 1, 2: 1, 3: 1, 4: 0};

void main() {
  const root = FilePath('/repo');
  const members = [
    WorkspaceMember(
      name: PackageName('na_kernel'),
      directory: FilePath('/repo/packages/core/na_kernel'),
    ),
    WorkspaceMember(
      name: PackageName('feature_meetings'),
      directory: FilePath('/repo/packages/features/feature_meetings'),
    ),
    WorkspaceMember(
      name: PackageName('adapter_bmlt'),
      directory: FilePath('/repo/packages/adapters/adapter_bmlt'),
    ),
  ];

  CoveragePolicy policy({
    final List<String> excludes = const ['**/*.g.dart'],
  }) =>
      (CoveragePolicy.parse(
                yamlText: aCoverageYaml(
                  packages: const {'na_kernel': 95},
                  excludes: excludes,
                ),
              )
              as CoveragePolicyParsed)
          .policy;

  LcovDocument merged() => LcovDocument.merge(
    documents: [
      const LcovParser().parse(
        text:
            '${aLcovFile(file: '$kernel/a.dart', hits: kernelHits)}'
            '${aLcovFile(file: '$feature/m.dart', hits: {1: 1, 2: 1})}'
            '${aLcovFile(file: '$adapter/b.dart', hits: {1: 1, 2: 0})}'
            '${aLcovFile(file: '$adapter/gen.g.dart', hits: {1: 0, 2: 0})}',
      ),
    ],
  );

  test('parses coverage.yaml', () {
    final p = policy();
    expect(p.mergedMinimum.value, 80);
    expect(p.featureDefault.value, 95);
    expect(p.adapterDefault.value, 80);
    expect(
      p.floorFor(package: const PackageName('na_kernel')),
      isA<FloorRequired>(),
    );
    expect(p.floorFor(package: const PackageName('na_cli')), isA<FloorNone>());
    expect(
      (p.floorFor(package: const PackageName('feature_x')) as FloorRequired)
          .minimum
          .value,
      95,
    );
    expect(
      (p.floorFor(package: const PackageName('adapter_x')) as FloorRequired)
          .minimum
          .value,
      80,
    );
  });

  test('glob patterns match generated files', () {
    const pattern = GlobPattern('**/*.g.dart');
    expect(pattern.match(path: 'lib/x.g.dart'), GlobMatch.matches);
    expect(
      pattern.match(path: 'packages/a/lib/deep/x.g.dart'),
      GlobMatch.matches,
    );
    expect(pattern.match(path: 'lib/x.dart'), GlobMatch.differs);
    expect(
      const GlobPattern('**/generated/**').match(path: 'lib/generated/a.dart'),
      GlobMatch.matches,
    );
  });

  test('reports offenders against floors and excludes patterns', () {
    final report = CoverageReport.evaluate(
      merged: merged(),
      policy: policy(),
      members: members,
      repoRoot: root,
    );
    expect(report.packages.map((final p) => p.package.value), [
      'adapter_bmlt',
      'feature_meetings',
      'na_kernel',
    ]);
    expect(report.total.value, closeTo(75, 0.01));
    expect(report.offences.map((final o) => o.scope), [
      'merged',
      'adapter_bmlt',
      'na_kernel',
    ]);
  });

  test('renders a markdown table with statuses', () {
    final markdown = const CoverageMarkdown().render(
      report: CoverageReport.evaluate(
        merged: merged(),
        policy: policy(),
        members: members,
        repoRoot: root,
      ),
    );
    expect(markdown, contains('| Package | Lines | Coverage | Status |'));
    expect(markdown, contains('| feature_meetings | 2/2 | 100.0% | ok |'));
    expect(markdown, contains('| na_kernel | 3/4 | 75.0% | below floor |'));
    expect(markdown, contains('| **merged** |  | 75.0% | below floor |'));
  });

  test('rejects malformed yaml', () {
    expect(
      CoveragePolicy.parse(yamlText: 'merged: [unclosed'),
      isA<CoveragePolicyRejected>(),
    );
  });
}
