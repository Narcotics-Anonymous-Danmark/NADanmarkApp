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
  late ConsoleMimic console;
  late FileSystemMimic files;

  setUp(() {
    console = ConsoleMimic();
    files = FileSystemMimic(
      files: {
        '$testRoot/tool/toolchain.env': 'ANDROID_AVD_NAME=na_avd\n',
        '/repo/env/dev.json': jsonEncode({'GOOGLE_MAPS_API_KEY': 'dev-key'}),
      },
    );
  });

  test('emulator start boots the AVD and waits for boot', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRunSequence(
          match: 'flutter devices --machine',
          outcomes: [
            anOutcome(stdout: aDevicesJson()),
            anOutcome(stdout: aDevicesJson(devices: [aDevice()])),
          ],
        ),
        whenRunSequence(
          match:
              '/home/tester/Android/Sdk/platform-tools/adb shell getprop '
              'sys.boot_completed',
          outcomes: [
            anOutcome(stdout: ''),
            anOutcome(stdout: '1\n'),
          ],
        ),
      ],
    );
    final sleeper = SleeperMimic();
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        processes: runner,
        sleeper: sleeper,
      ),
      arguments: ['emulator', 'start'],
    );
    expect(code.value, 0);
    expect(runner.displays, contains('flutter emulators --launch na_avd'));
    expect(sleeper.sleeps, hasLength(1));
    expect(console.outLines.last, 'emulator ready: emulator-5554');
  });

  test(
    'run picks the physical device, writes Secrets.xcconfig, passes args',
    () async {
      final runner = ProcessRunnerMimic(
        responses: [
          whenRun(
            match: 'flutter devices --machine',
            stdout: aDevicesJson(
              devices: [
                aDevice(),
                aDevice(id: 'phone', emulator: false),
              ],
            ),
          ),
        ],
      );
      final code = await runCli(
        context: aContext(files: files, console: console, processes: runner),
        arguments: ['run', '--', '--verbose'],
      );
      expect(code.value, 0);
      final flutterRun = runner.passedThrough.single;
      expect(
        flutterRun.display,
        'flutter run -d phone --dart-define-from-file=../env/dev.json '
        '--verbose',
      );
      expect(flutterRun.environment, {'GOOGLE_MAPS_API_KEY': 'dev-key'});
      expect(
        files.texts['/repo/app/ios/Flutter/Secrets.xcconfig'],
        'GOOGLE_MAPS_API_KEY = dev-key\n',
      );
    },
  );

  test('run --device fails when only emulators exist', () async {
    final runner = ProcessRunnerMimic(
      responses: [
        whenRun(
          match: 'flutter devices --machine',
          stdout: aDevicesJson(devices: [aDevice()]),
        ),
      ],
    );
    final code = await runCli(
      context: aContext(files: files, console: console, processes: runner),
      arguments: ['run', '--device'],
    );
    expect(code.value, 1);
    expect(console.errLines.single, contains('no physical device connected'));
  });

  test('emulator stop kills adb emulators', () async {
    final runner = ProcessRunnerMimic();
    await runCli(
      context: aContext(files: files, console: console, processes: runner),
      arguments: ['emulator', 'stop'],
    );
    expect(runner.displays, [
      '/home/tester/Android/Sdk/platform-tools/adb emu kill',
    ]);
  });
}
