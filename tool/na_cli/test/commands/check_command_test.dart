@Tags(['unit'])
library;

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

  Future<int> run(
    final List<String> args, {
    final FileSystemMimic? files,
    final ProcessRunnerMimic? processes,
  }) async => (await runCli(
    context: aContext(files: files, console: console, processes: processes),
    arguments: ['check', ...args],
  )).value;

  test('commit-msg accepts a literal message', () async {
    expect(await run(['commit-msg', 'feat(cli): hello']), 0);
    expect(console.outLines.single, 'commit message ok: feat(cli): hello');
  });

  test('commit-msg reads the file lefthook passes', () async {
    final files = FileSystemMimic(
      files: {'/repo/.git/COMMIT_EDITMSG': 'oops\n'},
    );
    expect(await run(['commit-msg', '.git/COMMIT_EDITMSG'], files: files), 1);
    expect(console.errLines.single, contains('not a conventional commit'));
  });

  test('commit-msg without an argument is a usage error', () async {
    expect(await run(['commit-msg']), 64);
  });

  test('arb reports divergence', () async {
    final files = FileSystemMimic(
      files: {
        '/repo/packages/core/na_l10n/lib/l10n/app_en.arb': '{"a":"A","b":"B"}',
        '/repo/packages/core/na_l10n/lib/l10n/app_da.arb': '{"a":"A"}',
      },
    );
    expect(await run(['arb'], files: files), 1);
    expect(console.errLines, ['arb: missing in app_da.arb: b']);
  });

  test('deps walks the workspace members', () async {
    final files = FileSystemMimic(
      files: {
        '/repo/pubspec.yaml': aRootPubspec(
          members: const [
            'packages/core/na_kernel',
            'packages/adapters/adapter_x',
          ],
        ),
        '/repo/packages/core/na_kernel/pubspec.yaml': aPubspec(),
        '/repo/packages/adapters/adapter_x/pubspec.yaml': aPubspec(
          name: 'adapter_x',
          dependencies: const ['na_design'],
        ),
        '/repo/packages/adapters/adapter_x/pubspec.lock': '',
      },
    );
    expect(await run(['deps'], files: files), 1);
    expect(console.errLines.single, contains('may not depend on na_design'));
    expect(console.errLines.single, contains('has its own pubspec.lock'));
  });

  test('format --check delegates to dart format', () async {
    final processes = ProcessRunnerMimic();
    expect(await run(['format'], processes: processes), 0);
    expect(processes.passedThroughDisplays, [
      'dart format --line-length=80 --set-exit-if-changed --output=none .',
    ]);
  });

  test('unknown check is a usage error', () async {
    expect(await run(['nope']), 64);
  });
}
