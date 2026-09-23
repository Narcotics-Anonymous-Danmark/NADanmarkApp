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
  late ConsoleMimic console;

  setUp(() => console = ConsoleMimic());

  FileSystemMimic workspace() => FileSystemMimic(
    files: {
      '/repo/pubspec.yaml': aRootPubspec(
        members: const [
          'app',
          'packages/core/na_kernel',
          'packages/core/na_design',
        ],
      ),
      appPubspecPath: aPubspec(name: 'na_app', dependencies: const ['flutter']),
      '/repo/packages/core/na_kernel/pubspec.yaml': aPubspec(
        devDependencies: const ['build_runner'],
      ),
      '/repo/packages/core/na_kernel/test/a_test.dart': '',
      '/repo/packages/core/na_design/pubspec.yaml': aPubspec(
        name: 'na_design',
        dependencies: const ['flutter'],
      ),
      '/repo/packages/core/na_design/test/w_test.dart': '',
    },
  );

  test(
    'test unit widget runs each member with the right tool and summarises',
    () async {
      final runner = ProcessRunnerMimic(
        responses: [
          whenRun(
            match: 'flutter test --tags widget',
            exitCode: 1,
            stdout: 'boom',
          ),
        ],
      );
      final code = await runCli(
        context: aContext(
          files: workspace(),
          console: console,
          processes: runner,
        ),
        arguments: ['test', 'unit', 'widget'],
      );
      expect(code.value, 1);
      expect(runner.displays, [
        'dart test --tags unit',
        'flutter test --tags unit',
        'flutter test --tags widget',
      ]);
      expect(console.outLines.last, contains('na_design:widget  failed'));
      expect(console.outLines.last, contains('na_kernel:unit    passed'));
    },
  );

  test('suites with no matching tags are skipped, not failed', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRun(match: 'dart test --tags unit', exitCode: 79),
        whenRun(
          match: 'flutter test --tags unit',
          stdout: 'No tests match the requested tag selectors',
        ),
      ],
    );
    final code = await runCli(
      context: aContext(
        files: workspace(),
        console: console,
        processes: runner,
      ),
      arguments: ['test', 'unit'],
    );
    expect(code.value, 0);
    expect(console.outLines.last, contains('na_kernel:unit  skipped'));
    expect(console.outLines.last, contains('na_design:unit  skipped'));
  });

  test('a skipped dart suite does not run format_coverage', () async {
    final runner = ProcessRunnerMimic(
      responses: [whenRun(match: 'dart test --tags unit', exitCode: 79)],
    );
    await runCli(
      context: aContext(
        files: workspace(),
        console: console,
        processes: runner,
      ),
      arguments: ['test', 'unit', '--package', 'na_kernel', '--coverage'],
    );
    expect(
      runner.displays.where((final d) => d.contains('format_coverage')),
      isEmpty,
    );
  });

  test('acceptance and e2e run in app/ and collect patrol coverage', () async {
    final files = workspace()
      ..writeText(
        path: const FilePath('/repo/app/coverage/patrol_lcov.info'),
        text: 'SF:x',
      );
    final runner = ProcessRunnerMimic();
    final code = await runCli(
      context: aContext(files: files, console: console, processes: runner),
      arguments: [
        'test',
        'e2e',
        'ios',
        'acceptance',
        '--device',
        'UDID-1',
        '--coverage',
      ],
    );
    expect(code.value, 0);
    const acceptance =
        'flutter test test_acceptance --coverage '
        '--coverage-path /repo/coverage/na_app.acceptance.lcov.info';
    const e2e =
        'patrol test --coverage -d UDID-1 '
        '--dart-define-from-file=../env/test.json';
    expect(runner.passedThroughDisplays, [acceptance, e2e]);
    expect(
      runner.passedThrough.every(
        (final c) => c.workingDirectory.value == '/repo/app',
      ),
      isTrue,
    );
    expect(files.texts['/repo/coverage/e2e-ios.lcov.info'], 'SF:x');
  });

  test('--file, --name and --update-goldens reach the runner', () async {
    final runner = ProcessRunnerMimic();
    final code = await runCli(
      context: aContext(
        files: workspace(),
        console: console,
        processes: runner,
      ),
      arguments: [
        'test',
        'widget',
        '--file',
        'packages/core/na_design/test/w_test.dart',
        '--name',
        'renders',
        '--update-goldens',
      ],
    );
    expect(code.value, 0);
    expect(runner.displays, [
      'flutter test test/w_test.dart --plain-name renders --update-goldens',
    ]);
    expect(
      runner.captured.single.workingDirectory.value,
      '/repo/packages/core/na_design',
    );
  });

  test('acceptance honours --name and --update-goldens', () async {
    final runner = ProcessRunnerMimic();
    await runCli(
      context: aContext(
        files: workspace(),
        console: console,
        processes: runner,
      ),
      arguments: ['test', 'acceptance', '--name', 'login', '--update-goldens'],
    );
    expect(runner.passedThroughDisplays, [
      'flutter test test_acceptance --plain-name login --update-goldens',
    ]);
  });

  test('e2e --develop runs patrol develop with the target', () async {
    final runner = ProcessRunnerMimic();
    await runCli(
      context: aContext(
        files: workspace(),
        console: console,
        processes: runner,
      ),
      arguments: [
        'test',
        'e2e',
        '--develop',
        '--target',
        'integration_test/x_test.dart',
      ],
    );
    expect(runner.passedThroughDisplays, [
      'patrol develop -t integration_test/x_test.dart',
    ]);
  });

  test(
    'gen all runs pub get then gen-l10n and fails on untranslated messages',
    () async {
      final files = workspace()
        ..writeText(
          path: const FilePath('/repo/packages/core/na_l10n/untranslated.json'),
          text: '{"da": ["hello"]}',
        );
      final runner = ProcessRunnerMimic();
      final code = await runCli(
        context: aContext(files: files, console: console, processes: runner),
        arguments: ['gen', 'all'],
      );
      expect(code.value, 1);
      expect(runner.passedThroughDisplays, [
        'flutter pub get',
        'dart run build_runner build --delete-conflicting-outputs',
        'flutter gen-l10n',
      ]);
      expect(
        runner.passedThrough.last.workingDirectory.value,
        '/repo/packages/core/na_l10n',
      );
      expect(console.errLines.single, contains('untranslated messages remain'));
    },
  );

  test(
    'gen json runs build_runner only where it is a dev dependency',
    () async {
      final runner = ProcessRunnerMimic();
      final code = await runCli(
        context: aContext(
          files: workspace(),
          console: console,
          processes: runner,
        ),
        arguments: ['gen', 'json'],
      );
      expect(code.value, 0);
      expect(runner.passedThroughDisplays, [
        'dart run build_runner build --delete-conflicting-outputs',
      ]);
      expect(
        runner.passedThrough.single.workingDirectory.value,
        '/repo/packages/core/na_kernel',
      );
    },
  );
}
