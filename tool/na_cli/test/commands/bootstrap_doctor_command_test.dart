@Tags(['unit'])
library;

import 'package:na_cli/src/fs/file_path.dart';
import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/file_system_mimic.dart';
import '../support/process_runner_mimic.dart';
import '../support/run_cli.dart';
import '../support/simple_mimics.dart';

void main() {
  late ConsoleMimic console;

  setUp(() => console = ConsoleMimic());

  FileSystemMimic files({
    final int instances = 128,
    final int watches = 65536,
  }) => FileSystemMimic(
    files: {
      '$testRoot/tool/toolchain.env': [
        'ANDROID_CMDLINE_TOOLS_VERSION=1',
        'ANDROID_CMDLINE_TOOLS_PACKAGE=19.0',
        'ANDROID_PLATFORM=android-35',
        'ANDROID_BUILD_TOOLS=35.0.0',
        'ANDROID_SYSTEM_IMAGE=system-images;android-35;google_apis;x86_64',
        'ANDROID_AVD_NAME=na_avd',
        'ANDROID_AVD_DEVICE=pixel_6',
        'XCODE_MINIMUM_MAJOR=16',
        'PATROL_CLI_VERSION=4.7.0',
        'JAVA_VERSION=17',
      ].join('\n'),
      '$testRoot/.fvmrc': '{"flutter": "3.41.3"}',
      '/proc/sys/fs/inotify/max_user_instances': '$instances\n',
      '/proc/sys/fs/inotify/max_user_watches': '$watches\n',
    },
  );

  test(
    'bootstrap --dry-run only runs checks and prints [run]/[skip]',
    () async {
      final runner = ProcessRunnerMimic(
        responses: [whenRun(match: 'bash -c find', stdout: '10\n')],
      );
      final code = await runCli(
        context: aContext(files: files(), console: console, processes: runner),
        arguments: ['bootstrap', '--dry-run'],
      );
      expect(code.value, 0);
      expect(runner.passedThrough, isEmpty);
      expect(
        console.outLines.where((final l) => l.startsWith('[run]')),
        isNotEmpty,
      );
      expect(
        console.outLines.any((final l) => l.contains('AVD na_avd')),
        isTrue,
      );
      expect(
        console.outLines.any(
          (final l) => l.contains('flutter precache --android'),
        ),
        isTrue,
      );
      expect(console.outLines.any((final l) => l.contains('Xcode')), isFalse);
    },
  );

  test(
    'bootstrap warns about exhausted inotify limits and continues',
    () async {
      final runner = ProcessRunnerMimic(
        responses: [whenRun(match: 'bash -c find', stdout: '120\n')],
      );
      await runCli(
        context: aContext(files: files(), console: console, processes: runner),
        arguments: ['bootstrap', '--dry-run'],
      );
      expect(
        console.errLines.single,
        contains('sudo sysctl -w fs.inotify.max_user_instances=1024'),
      );
    },
  );

  test('doctor reports the inotify blocker in the table and exits 1', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRun(match: 'bash -c find', stdout: '120\n'),
        whenMissing(match: 'which patrol'),
      ],
    );
    final code = await runCli(
      context: aContext(files: files(), console: console, processes: runner),
      arguments: ['doctor'],
    );
    expect(code.value, 1);
    expect(runner.passedThroughDisplays, ['flutter doctor -v']);
    expect(console.outLines.last, contains('inotify limits'));
    expect(console.outLines.last, contains('blocker'));
  });

  test('a healthy linux host only misses the always-run steps', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRun(match: 'bash -c find', stdout: '10\n'),
        whenRun(
          match: '/home/tester/Android/Sdk/emulator/emulator -list-avds',
          stdout: 'na_avd\n',
        ),
        whenRun(
          match: 'flutter config --machine',
          stdout: '{"android-sdk":"/home/tester/Android/Sdk"}',
        ),
        whenRun(match: 'patrol --version', stdout: 'patrol_cli v4.7.0'),
        whenRun(
          match: 'flutter --version --machine',
          stdout: '{"frameworkVersion":"3.41.3"}',
        ),
        whenRun(
          match: 'java -version',
          stdout: 'openjdk version "17.0.20" 2026-07-21',
        ),
      ],
    );
    final fs = files(instances: 1024, watches: 1048576);
    for (final path in [
      '/home/tester/Android/Sdk/cmdline-tools/latest/bin/sdkmanager',
      '/home/tester/Android/Sdk/licenses/android-sdk-license',
      '/home/tester/Android/Sdk/platform-tools/adb',
      '/home/tester/Android/Sdk/platforms/android-35/x',
      '/home/tester/Android/Sdk/build-tools/35.0.0/x',
      '/home/tester/Android/Sdk/emulator/emulator',
      '/home/tester/Android/Sdk/system-images/android-35/google_apis/x86_64/x',
      '/repo/.git/hooks/pre-commit',
      '/repo/.dart_tool/package_config.json',
    ]) {
      fs.writeText(path: FilePath(path), text: '');
    }
    final code = await runCli(
      context: aContext(files: fs, console: console, processes: runner),
      arguments: ['doctor'],
    );
    final missing = console.outLines
        .where((final l) => l.startsWith('[MISS]'))
        .toList();
    expect(missing.map((final l) => l.substring(7)), [
      'na gen all',
      'flutter precache --android',
    ]);
    expect(code.value, 1);
  });

  test(
    'doctor lists the pinned Flutter and JDK as missing when they differ',
    () async {
      final runner = ProcessRunnerMimic(
        responses: [
          whenRun(match: 'bash -c find', stdout: '10\n'),
          whenRun(
            match: 'flutter --version --machine',
            stdout: '{"frameworkVersion":"3.40.0"}',
          ),
          whenRun(match: 'java -version', stdout: 'openjdk version "21.0.1"'),
        ],
      );
      await runCli(
        context: aContext(files: files(), console: console, processes: runner),
        arguments: ['doctor'],
      );
      final missing = console.outLines
          .where((final l) => l.startsWith('[MISS]'))
          .map((final l) => l.substring(7));
      expect(missing, containsAll(['Flutter 3.41.3 (.fvmrc)', 'JDK 17']));
    },
  );

  test('cmdline-tools is needed until cmdline-tools/latest exists', () async {
    final fs = files(instances: 1024, watches: 1048576)
      ..writeText(
        path: const FilePath(
          '/home/tester/Android/Sdk/cmdline-tools/tools/bin/sdkmanager',
        ),
        text: '',
      );
    await runCli(
      context: aContext(files: fs, console: console),
      arguments: ['bootstrap', '--dry-run'],
    );
    expect(
      console.outLines,
      contains(startsWith('[run]  Android cmdline-tools 19.0 (build 1)')),
    );
  });
}
