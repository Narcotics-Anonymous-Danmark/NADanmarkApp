import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/steps/step.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/tool_presence.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

final class CommonSteps {
  const CommonSteps({required this.context, required this.settings});

  final CliContext context;
  final ToolchainSettings settings;

  List<Step> all({required final List<ReleasePlatform> platforms}) => [
    flutterSdk(),
    java(),
    lcov(),
    patrolCli(),
    lefthook(),
    pubGet(),
    gen(),
    ...platforms.map((final platform) => precache(platform: platform)),
  ];

  Step flutterSdk() => Step(
    name: 'Flutter ${settings.flutterVersion} (.fvmrc)',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['flutter', '--version', '--machine']),
      );
      return outcome is ProcessSucceeded &&
              outcome.stdout.contains('"${settings.flutterVersion}"')
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () async {
      switch (await Shell(
        context: context,
      ).locate(executable: const Executable('fvm'))) {
        case ToolFound():
          await _run(['fvm', 'install', settings.flutterVersion]);
        case ToolMissing():
          context.console.err(
            line:
                'install fvm (https://fvm.app) or put Flutter '
                '${settings.flutterVersion} on PATH, then rerun ./bin/na',
          );
      }
    },
  );

  Step java() => Step(
    name: 'JDK ${settings.javaVersion}',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['java', '-version']),
      );
      return outcome is ProcessSucceeded &&
              outcome.combinedOutput.contains(
                'version "${settings.javaVersion}.',
              )
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () async {
      switch (context.hostOs) {
        case HostOs.macos:
          await _run([
            'brew',
            'install',
            '--cask',
            'temurin@${settings.javaVersion}',
          ]);
        case HostOs.linux:
          switch (await Shell(
            context: context,
          ).locate(executable: const Executable('sudo'))) {
            case ToolFound():
              await _run([
                'sudo',
                'apt-get',
                'install',
                '-y',
                'openjdk-${settings.javaVersion}-jdk',
              ]);
            case ToolMissing():
              context.console.err(
                line:
                    'install a JDK ${settings.javaVersion} manually '
                    '(no sudo found)',
              );
          }
      }
    },
  );

  Step lcov() => Step(
    name: 'lcov (genhtml)',
    check: () => _onPath('genhtml'),
    run: () async {
      switch (context.hostOs) {
        case HostOs.macos:
          await _run(const ['brew', 'install', 'lcov']);
        case HostOs.linux:
          switch (await Shell(
            context: context,
          ).locate(executable: const Executable('sudo'))) {
            case ToolFound():
              await _run(const ['sudo', 'apt-get', 'install', '-y', 'lcov']);
            case ToolMissing():
              context.console.err(
                line:
                    'install lcov manually: apt-get install lcov '
                    '(no sudo found)',
              );
          }
      }
    },
  );

  Step patrolCli() => Step(
    name: 'patrol_cli ${settings.patrolCliVersion}',
    check: () async {
      final outcome = await context.processes.capture(
        command: _command(const ['patrol', '--version']),
      );
      return outcome is ProcessSucceeded &&
              outcome.stdout.contains(settings.patrolCliVersion)
          ? StepState.satisfied
          : StepState.needed;
    },
    run: () => _run([
      'dart',
      'pub',
      'global',
      'activate',
      'patrol_cli',
      settings.patrolCliVersion,
    ]),
  );

  Step lefthook() => Step(
    name: 'lefthook install',
    check: () async => _fileState(
      context.repoRoot.joinAll(['.git', 'hooks', 'pre-commit']),
    ),
    run: () => _run(const ['lefthook', 'install']),
  );

  Step pubGet() => Step(
    name: 'flutter pub get',
    check: () async => _fileState(
      context.repoRoot.joinAll(['.dart_tool', 'package_config.json']),
    ),
    run: () => _run(const ['flutter', 'pub', 'get']),
  );

  Step gen() => Step(
    name: 'na gen all',
    check: () async => StepState.needed,
    run: () => _run(const ['dart', 'run', 'na_cli', 'gen', 'all']),
  );

  Step precache({required final ReleasePlatform platform}) => Step(
    name: 'flutter precache --${platform.name}',
    check: () async => StepState.needed,
    run: () => _run(['flutter', 'precache', '--${platform.name}']),
  );

  StepState _fileState(final FilePath path) =>
      switch (context.files.status(path: path)) {
        PathStatus.file => StepState.satisfied,
        PathStatus.directory || PathStatus.missing => StepState.needed,
      };

  Future<StepState> _onPath(final String tool) async => switch (await Shell(
    context: context,
  ).locate(executable: Executable(tool))) {
    ToolFound() => StepState.satisfied,
    ToolMissing() => StepState.needed,
  };

  Future<void> _run(final List<String> command) =>
      Shell(context: context).passThroughOrFail(command: _command(command));

  CommandLine _command(final List<String> command) => CommandLine.at(
    executable: Executable(command.first),
    arguments: command.sublist(1),
    workingDirectory: context.repoRoot,
  );
}
