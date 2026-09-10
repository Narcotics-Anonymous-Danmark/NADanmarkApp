import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/steps/step.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/tool_presence.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

final class IosSteps {
  const IosSteps({required this.context, required this.settings});

  final CliContext context;
  final ToolchainSettings settings;

  List<Step> all() => [
    xcode(),
    xcodeLicense(),
    firstLaunch(),
    cocoapods(),
    simulator(),
    podInstall(),
  ];

  Step xcode() => Step(
    name: 'Xcode >= ${settings.xcodeMinimumMajor}',
    check: () async {
      final selected = await context.processes.capture(
        command: _command(const ['xcode-select', '-p']),
      );
      final version = await context.processes.capture(
        command: _command(const ['xcodebuild', '-version']),
      );
      final majors = RegExp(r'Xcode (\d+)')
          .allMatches(version.stdout)
          .map((final m) => int.parse(m.group(1).toString()));
      return selected is ProcessSucceeded &&
              majors.isNotEmpty &&
              majors.first >= settings.xcodeMinimumMajor
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () async => throw CliFailure.general(
      message: [
        'Xcode ${settings.xcodeMinimumMajor} or newer is required:',
        '  1. Install Xcode from the App Store or developer.apple.com',
        '  2. sudo xcode-select -s /Applications/Xcode.app/Contents/Developer',
        '  3. re-run ./bin/na bootstrap ios',
      ].join('\n'),
    ),
  );

  Step xcodeLicense() => Step(
    name: 'Xcode license accepted',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['xcodebuild', '-checkFirstLaunchStatus']),
      );
      return outcome is ProcessSucceeded
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => _run(const ['sudo', 'xcodebuild', '-license', 'accept']),
  );

  Step firstLaunch() => Step(
    name: 'xcodebuild -runFirstLaunch',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['xcodebuild', '-checkFirstLaunchStatus']),
      );
      return outcome is ProcessSucceeded
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => _run(const ['xcodebuild', '-runFirstLaunch']),
  );

  Step cocoapods() => Step(
    name: 'CocoaPods',
    check: () async => switch (await Shell(
      context: context,
    ).locate(executable: const Executable('pod'))) {
      ToolFound() => StepState.satisfied,
      ToolMissing() => StepState.needed,
    },
    run: () => _run(const ['brew', 'install', 'cocoapods']),
  );

  Step simulator() => Step(
    name: 'Simulator "${settings.iosSimulatorName}"',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['xcrun', 'simctl', 'list', 'devices', '-j']),
      );
      return outcome.stdout.contains('"name" : "${settings.iosSimulatorName}"')
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () async {
      final runtimes = await Shell(context: context).captureOrFail(
        command: _command(const ['xcrun', 'simctl', 'list', 'runtimes']),
      );
      final ids = RegExp(r'(com\.apple\.CoreSimulator\.SimRuntime\.iOS-[\d-]+)')
          .allMatches(runtimes)
          .map((final m) => m.group(1).toString())
          .toList(growable: false);
      if (ids.isEmpty) {
        throw const CliFailure.general(
          message: 'no iOS simulator runtime installed; install one in Xcode',
        );
      }
      await _run([
        'xcrun',
        'simctl',
        'create',
        settings.iosSimulatorName,
        settings.iosSimulatorDeviceType,
        ids.last,
      ]);
    },
  );

  Step podInstall() => Step(
    name: 'pod install (app/ios)',
    check: () async => switch (context.files.status(
      path: context.appDir.joinAll(['ios', 'Pods', 'Manifest.lock']),
    )) {
      PathStatus.file => StepState.satisfied,
      PathStatus.directory || PathStatus.missing => StepState.needed,
    },
    run: () async {
      final iosDir = context.appDir.join('ios');
      final first = await Shell(context: context).passThrough(
        command: CommandLine.at(
          executable: const Executable('pod'),
          arguments: const ['install'],
          workingDirectory: iosDir,
        ),
      );
      if (first is ProcessSucceeded) {
        return;
      }
      await Shell(context: context).passThroughOrFail(
        command: CommandLine.at(
          executable: const Executable('pod'),
          arguments: const ['install', '--repo-update'],
          workingDirectory: iosDir,
        ),
      );
    },
  );

  Future<void> _run(final List<String> command) =>
      Shell(context: context).passThroughOrFail(command: _command(command));

  CommandLine _command(final List<String> command) => CommandLine.at(
    executable: Executable(command.first),
    arguments: command.sublist(1),
    workingDirectory: context.repoRoot,
  );
}
