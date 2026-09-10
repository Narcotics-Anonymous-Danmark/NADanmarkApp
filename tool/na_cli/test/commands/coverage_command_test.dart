@Tags(['unit'])
library;

import 'package:na_cli/src/fs/file_path.dart';
import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/builders.dart';
import '../support/file_system_mimic.dart';
import '../support/process_runner_mimic.dart';
import '../support/run_cli.dart';
import '../support/simple_mimics.dart';

void main() {
  late FileSystemMimic files;
  late ConsoleMimic console;

  setUp(() {
    files = FileSystemMimic(
      files: {
        '/repo/pubspec.yaml': aRootPubspec(
          members: const ['packages/core/na_kernel'],
        ),
        '/repo/packages/core/na_kernel/pubspec.yaml': aPubspec(),
        '/repo/coverage.yaml': aCoverageYaml(packages: const {'na_kernel': 90}),
        '/repo/coverage/na_kernel.unit.lcov.info': aLcovFile(
          hits: {1: 1, 2: 1, 3: 0, 4: 1},
        ),
        '/repo/coverage/na_kernel.widget.lcov.info': aLcovFile(hits: {3: 2}),
      },
    );
    console = ConsoleMimic();
  });

  Future<int> run(
    final List<String> args, {
    final Map<String, String> env = const {},
  }) async => (await runCli(
    context: aContext(files: files, console: console, environment: env),
    arguments: ['coverage', ...args],
  )).value;

  test(
    '--merge writes merged.lcov.info with repo-relative paths and summary.md',
    () async {
      expect(
        await run(['--merge'], env: {'GITHUB_STEP_SUMMARY': '/gh/summary'}),
        0,
      );
      expect(
        files.texts['/repo/coverage/merged.lcov.info'],
        'SF:packages/core/na_kernel/lib/a.dart\nDA:1,1\nDA:2,1\nDA:3,2\n'
        'DA:4,1\nLF:4\nLH:4\nend_of_record\n',
      );
      expect(
        files.texts['/repo/coverage/summary.md'],
        contains('| na_kernel | 4/4 | 100.0% | ok |'),
      );
      expect(files.texts['/gh/summary'], contains('## Coverage'));
    },
  );

  test('--check fails with a table of offenders', () async {
    files.writeText(
      path: const FilePath('/repo/coverage/na_kernel.widget.lcov.info'),
      text: aLcovFile(hits: {3: 0}),
    );
    expect(await run(['--check']), 1);
    expect(console.errLines.single, contains('na_kernel'));
    expect(console.errLines.single, contains('75.0%'));
  });

  test('--html warns when genhtml is missing', () async {
    final context = aContext(
      files: files,
      console: console,
      processes: ProcessRunnerMimic(
        responses: [whenMissing(match: 'which genhtml')],
      ),
    );
    expect(
      (await runCli(context: context, arguments: ['coverage', '--html'])).value,
      0,
    );
    expect(console.errLines.single, contains('genhtml'));
  });
}
