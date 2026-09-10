@Tags(['unit'])
library;

import 'dart:convert';

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

  const secrets = {
    'ANDROID_KEYSTORE_BASE64': 'a2V5c3RvcmU=',
    'ANDROID_KEYSTORE_PASSWORD': 'store-pw',
    'ANDROID_KEY_PASSWORD': 'key-pw',
  };

  setUp(() {
    files = FileSystemMimic(
      files: {
        appPubspecPath: aPubspec(name: 'na_app', version: '2.0.0+1120000001'),
        '/repo/env/release.json': jsonEncode({
          'NA_API_BASIC_AUTH': 'u:p',
          'GOOGLE_MAPS_API_KEY': 'maps-key',
        }),
        '/repo/app/build/app/outputs/bundle/release/app-release.aab': 'AAB',
      },
    );
    console = ConsoleMimic();
  });

  ProcessRunnerMimic processes({final String jarsigner = 'jar verified.'}) =>
      ProcessRunnerMimic(
        responses: [
          whenRun(match: 'git status --porcelain'),
          whenRun(match: 'which keytool', stdout: '/usr/bin/keytool'),
          whenRun(match: 'which jarsigner', stdout: '/usr/bin/jarsigner'),
          whenMissing(match: 'which xcodebuild'),
          whenMissing(match: 'which security'),
          whenMissing(match: 'which xcrun'),
          whenRun(match: 'jarsigner -verify', stdout: jarsigner),
        ],
      );

  Future<int> run(
    final List<String> args, {
    required final ProcessRunnerMimic runner,
    final Map<String, String> environment = secrets,
  }) async => (await runCli(
    context: aContext(
      files: files,
      console: console,
      processes: runner,
      environment: environment,
    ),
    arguments: ['release', ...args],
  )).value;

  test('check lists every blocker and exits 1', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRun(match: 'git status --porcelain', stdout: ' M file'),
        whenMissing(match: 'which'),
      ],
    );
    expect(
      await run(['check', 'android'], runner: runner, environment: const {}),
      1,
    );
    final message = console.errLines.single;
    expect(message, contains('git worktree is dirty'));
    expect(message, contains('ANDROID_KEYSTORE_BASE64'));
    expect(message, contains('keytool is not on PATH'));
  });

  test('android --dry-run prints the plan without building', () async {
    final runner = processes();
    expect(await run(['android', '--dry-run'], runner: runner), 0);
    expect(runner.passedThrough, isEmpty);
    expect(
      console.outLines.last,
      'dry-run: would write /repo/dist/nadanmark-2.0.0-1.aab',
    );
    expect(
      console.outLines[console.outLines.length - 2],
      contains(
        'flutter build appbundle --release '
        '--dart-define-from-file=../env/release.json '
        '--build-name 2.0.0 --build-number 1120000001',
      ),
    );
  });

  test('android builds, verifies, copies and cleans up', () async {
    final runner = processes();
    expect(await run(['android', '--output', 'out'], runner: runner), 0);
    final build = runner.passedThrough.single;
    expect(build.workingDirectory.value, '/repo/app');
    expect(build.environment, {
      'GOOGLE_MAPS_API_KEY': 'maps-key',
      'NA_KEY_PROPERTIES': '/repo/.na-release/key.properties',
    });
    expect(
      runner.displays.where((final d) => d.startsWith('keytool -list')).single,
      'keytool -list -keystore /repo/.na-release/upload.keystore '
      '-storepass store-pw -alias nadanmarkapp',
    );
    expect(files.texts['/repo/out/nadanmark-2.0.0-1.aab'], 'AAB');
    expect(files.deleted, contains('/repo/.na-release'));
    expect(
      files.texts.keys.where((final k) => k.startsWith('/repo/.na-release')),
      isEmpty,
    );
  });

  test(
    'a failed jarsigner verification fails the release and still cleans up',
    () async {
      final runner = processes(jarsigner: 'jar is unsigned.');
      expect(await run(['android'], runner: runner), 1);
      expect(console.errLines.single, contains('jar verified'));
      expect(files.deleted, contains('/repo/.na-release'));
    },
  );

  test('ANDROID_KEY_ALIAS overrides the conventional alias', () async {
    final runner = processes();
    expect(
      await run(
        ['android'],
        runner: runner,
        environment: {...secrets, 'ANDROID_KEY_ALIAS': 'other'},
      ),
      0,
    );
    expect(
      runner.displays.any((final d) => d.endsWith('-alias other')),
      isTrue,
    );
  });
}
