import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/steps/step.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

final class AndroidSteps {
  const AndroidSteps({required this.context, required this.settings});

  final CliContext context;
  final ToolchainSettings settings;

  List<Step> all() => [
    cmdlineTools(),
    licenses(),
    sdkPackages(),
    avd(),
    flutterAndroidSdk(),
    flutterLicenses(),
  ];

  Step cmdlineTools() => Step(
    name:
        'Android cmdline-tools ${settings.cmdlineToolsPackage} '
        '(build ${settings.cmdlineToolsVersion}) as cmdline-tools/latest',
    check: () async => _present(_latestSdkManager.value),
    run: () async {
      switch (_present(settings.sdkManager.value)) {
        case StepState.satisfied:
          await _installClassicCmdlineTools();
        case StepState.needed:
          await _downloadCmdlineTools();
      }
    },
  );

  Future<void> _installClassicCmdlineTools() async {
    final latest = settings.androidHome.joinAll(['cmdline-tools', 'latest']);
    final install =
        'yes | "${settings.sdkManager.value}" '
        '"cmdline-tools;${settings.cmdlineToolsPackage}"';
    await Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('bash'),
        arguments: ['-c', install],
        workingDirectory: context.repoRoot,
      ),
    );
    await _sh(['rm', '-rf', latest.value]);
    await _sh(['ln', '-s', settings.cmdlineToolsPackage, latest.value]);
  }

  FilePath get _latestSdkManager => settings.androidHome.joinAll([
    'cmdline-tools',
    'latest',
    'bin',
    'sdkmanager',
  ]);

  Future<void> _downloadCmdlineTools() async {
    final suffix = context.hostOs.androidToolsSuffix;
    final zip = context.repoRoot.joinAll(['.na', 'cmdline-tools.zip']);
    final staging = context.repoRoot.joinAll(['.na', 'cmdline-tools']);
    final latest = settings.androidHome.joinAll(['cmdline-tools', 'latest']);
    final url =
        'https://dl.google.com/android/repository/'
        'commandlinetools-$suffix-'
        '${settings.cmdlineToolsVersion}_latest.zip';
    context.files.ensureDirectory(path: zip.parent);
    await _sh(['curl', '-fsSL', '-o', zip.value, url]);
    context.files.deleteTree(path: staging);
    await _sh(['unzip', '-q', zip.value, '-d', staging.value]);
    context.files.ensureDirectory(path: latest.parent);
    context.files.deleteTree(path: latest);
    await _sh(['mv', staging.join('cmdline-tools').value, latest.value]);
    context.files.deleteTree(path: zip.parent);
  }

  Step licenses() => Step(
    name: 'Android SDK licenses',
    check: () async => _present(
      settings.androidHome.joinAll(['licenses', 'android-sdk-license']).value,
    ),
    run: () => Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('bash'),
        arguments: ['-c', 'yes | "${settings.sdkManager.value}" --licenses'],
        workingDirectory: context.repoRoot,
      ),
    ),
  );

  Step sdkPackages() => Step(
    name:
        'Android platform ${settings.androidPlatform}, build-tools '
        '${settings.androidBuildTools}, emulator, system image',
    check: () async {
      final expected = [
        settings.androidHome.joinAll(['platform-tools', 'adb']).value,
        settings.androidHome.joinAll([
          'platforms',
          settings.androidPlatform,
        ]).value,
        settings.androidHome.joinAll([
          'build-tools',
          settings.androidBuildTools,
        ]).value,
        settings.emulator.value,
        settings.androidHome
            .joinAll(settings.androidSystemImage.split(';'))
            .value,
      ];
      return expected.every((final p) => _present(p) == StepState.satisfied)
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: Executable(settings.sdkManager.value),
        arguments: [
          'platform-tools',
          'platforms;${settings.androidPlatform}',
          'build-tools;${settings.androidBuildTools}',
          'emulator',
          settings.androidSystemImage,
        ],
        workingDirectory: context.repoRoot,
      ),
    ),
  );

  Step avd() => Step(
    name: 'AVD ${settings.avdName}',
    check: () async {
      final outcome = await context.processes.capture(
        command: CommandLine.at(
          executable: Executable(settings.emulator.value),
          arguments: const ['-list-avds'],
          workingDirectory: context.repoRoot,
        ),
      );
      return outcome.stdout
              .split('\n')
              .map((final l) => l.trim())
              .contains(
                settings.avdName,
              )
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('bash'),
        arguments: ['-c', _createAvdScript],
        workingDirectory: context.repoRoot,
      ),
    ),
  );

  String get _createAvdScript =>
      'echo no | "${settings.avdManager.value}" create avd '
      '-n "${settings.avdName}" -k "${settings.androidSystemImage}" '
      '-d "${settings.avdDevice}"';

  Step flutterAndroidSdk() => Step(
    name: 'flutter config --android-sdk',
    check: () async {
      final outcome = await context.processes.capture(
        command: _flutter(const ['config', '--machine']),
      );
      return outcome.stdout.contains(settings.androidHome.value)
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => Shell(context: context).passThroughOrFail(
      command: _flutter([
        'config',
        '--android-sdk',
        settings.androidHome.value,
      ]),
    ),
  );

  Step flutterLicenses() => Step(
    name: 'flutter doctor --android-licenses',
    check: () async {
      final outcome = await context.processes.capture(
        command: _flutter(const ['doctor']),
      );
      return outcome is ProcessSucceeded &&
              !outcome.stdout.contains('licenses not accepted') &&
              !outcome.stdout.contains('license status unknown')
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('bash'),
        arguments: const ['-c', 'yes | flutter doctor --android-licenses'],
        workingDirectory: context.repoRoot,
      ),
    ),
  );

  StepState _present(final String path) =>
      switch (context.files.status(path: FilePath(path))) {
        PathStatus.file || PathStatus.directory => StepState.satisfied,
        PathStatus.missing => StepState.needed,
      };

  Future<void> _sh(final List<String> command) =>
      Shell(context: context).captureOrFail(
        command: CommandLine.at(
          executable: Executable(command.first),
          arguments: command.sublist(1),
          workingDirectory: context.repoRoot,
        ),
      );

  CommandLine _flutter(final List<String> arguments) => CommandLine.at(
    executable: const Executable('flutter'),
    arguments: arguments,
    workingDirectory: context.repoRoot,
  );
}
