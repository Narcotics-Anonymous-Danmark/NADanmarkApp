@Tags(['unit'])
library;

import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/testing/test_job.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_options.dart';
import 'package:na_cli/src/testing/test_plan.dart';
import 'package:na_cli/src/testing/test_tool.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  TestCandidate candidate({
    required final String name,
    final List<String> deps = const [],
    final TestDirectory tests = TestDirectory.present,
  }) => TestCandidate(
    member: WorkspaceMember(
      name: PackageName(name),
      directory: FilePath('/repo/packages/$name'),
    ),
    manifest:
        (PackageManifest.parse(
                  pubspecText: aPubspec(name: name, dependencies: deps),
                  lockFile: LockFilePresence.absent,
                )
                as PackageManifestParsed)
            .manifest,
    testDirectory: tests,
  );

  final candidates = [
    candidate(name: 'na_kernel'),
    candidate(name: 'na_design', deps: ['flutter']),
    candidate(name: 'na_lints', tests: TestDirectory.absent),
  ];

  List<TestJob> plan({
    final List<TestLevel> levels = const [TestLevel.unit],
    final PackageFilter filter = const AllPackages(),
    final TestScope scope = const WholeSuite(),
    final TestOptions options = TestOptions.plain,
  }) => const TestPlan().jobs(
    candidates: candidates,
    levels: levels,
    filter: filter,
    scope: scope,
    options: options,
    coverageDir: const FilePath('/repo/coverage'),
    repoRoot: const FilePath('/repo'),
  );

  const withCoverage = TestOptions(
    coverage: CoverageCollection.on,
    nameFilter: AnyName(),
    goldens: GoldenPolicy.keep,
  );

  test('levels default to unit and "all" expands', () {
    expect(TestLevel.fromWords(words: const []), [TestLevel.unit]);
    expect(TestLevel.fromWords(words: const ['all']), TestLevel.values);
  });

  test(
    'unit jobs run in every member with a test dir, using the right tool',
    () {
      final jobs = plan();
      expect(jobs.map((final j) => j.label), [
        'na_kernel:unit',
        'na_design:unit',
      ]);
      expect(jobs[0].tool, TestTool.dart);
      expect(jobs[1].tool, TestTool.flutter);
      expect(jobs[0].commands.single.display, 'dart test --tags unit');
      expect(jobs[1].commands.single.display, 'flutter test --tags unit');
    },
  );

  test('widget jobs only target flutter packages', () {
    expect(plan(levels: const [TestLevel.widget]).map((final j) => j.label), [
      'na_design:widget',
    ]);
  });

  test('--package filters members', () {
    expect(
      plan(
        filter: const OnlyPackage(name: PackageName('na_kernel')),
      ).map((final j) => j.label),
      ['na_kernel:unit'],
    );
  });

  test('coverage adds lcov output per tool', () {
    final jobs = plan(options: withCoverage);
    expect(jobs[0].commands, hasLength(2));
    expect(
      jobs[0].commands[0].display,
      contains('--coverage=/repo/packages/na_kernel/coverage/raw/unit'),
    );
    expect(
      jobs[0].commands[1].display,
      'dart run coverage:format_coverage --lcov '
      '--packages=/repo/.dart_tool/package_config.json '
      '--report-on=/repo/packages/na_kernel/lib '
      '--in=/repo/packages/na_kernel/coverage/raw/unit '
      '-o /repo/coverage/na_kernel.unit.lcov.info',
    );
    expect(jobs[0].commands[1].workingDirectory.value, '/repo');
    expect(
      jobs[1].commands.single.display,
      'flutter test --tags unit --coverage '
      '--coverage-path /repo/coverage/na_design.unit.lcov.info',
    );
  });

  test('acceptance and e2e are not per-package jobs', () {
    expect(plan(levels: const [TestLevel.acceptance, TestLevel.e2e]), isEmpty);
  });

  test('--file runs only that file in the owning package', () {
    final jobs = plan(
      levels: const [TestLevel.widget],
      scope: const SingleFile(
        path: FilePath('/repo/packages/na_design/test/w_test.dart'),
      ),
    );
    expect(jobs.single.label, 'na_design:widget');
    expect(
      jobs.single.commands.single.display,
      'flutter test test/w_test.dart',
    );
    expect(
      jobs.single.commands.single.workingDirectory.value,
      '/repo/packages/na_design',
    );
  });

  test('--file outside every package plans nothing', () {
    expect(
      plan(scope: const SingleFile(path: FilePath('/elsewhere/x_test.dart'))),
      isEmpty,
    );
  });

  test('--name passes through as --plain-name for both tools', () {
    final jobs = plan(
      options: const TestOptions(
        coverage: CoverageCollection.off,
        nameFilter: PlainName(text: 'parses'),
        goldens: GoldenPolicy.keep,
      ),
    );
    expect(
      jobs[0].commands.single.display,
      'dart test --tags unit --plain-name parses',
    );
    expect(
      jobs[1].commands.single.display,
      'flutter test --tags unit --plain-name parses',
    );
  });

  test('--update-goldens only reaches flutter widget runs', () {
    const goldens = TestOptions(
      coverage: CoverageCollection.off,
      nameFilter: AnyName(),
      goldens: GoldenPolicy.update,
    );
    final unit = plan(options: goldens);
    expect(unit[0].commands.single.display, 'dart test --tags unit');
    expect(unit[1].commands.single.display, 'flutter test --tags unit');
    final widget = plan(levels: const [TestLevel.widget], options: goldens);
    expect(
      widget.single.commands.single.display,
      'flutter test --tags widget --update-goldens',
    );
    expect(
      goldens.passThroughArguments(
        tool: TestTool.flutter,
        level: TestLevel.acceptance,
      ),
      ['--update-goldens'],
    );
  });
}
