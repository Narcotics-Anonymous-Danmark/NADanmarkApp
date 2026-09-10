import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/devices/device_selector.dart';
import 'package:na_cli/src/devices/emulator_control.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/ios/secrets_xcconfig.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/tools/shell.dart';

final class RunCommand extends Command<int> {
  RunCommand({required this.context}) {
    argParser
      ..addFlag('device', negatable: false, help: 'Require a physical device.')
      ..addFlag('emulator', negatable: false, help: 'Prefer an emulator.')
      ..addOption('target', help: 'Exact device id.')
      ..addOption(
        'env',
        help: 'env/<name>.json (default dev).',
        allowed: ['dev', 'release'],
      )
      ..addFlag('release', negatable: false, help: 'Build in release mode.');
  }

  final CliContext context;

  @override
  String get name => 'run';

  @override
  String get description => 'Build and run the app on a device or emulator.';

  @override
  String get invocation =>
      'na run [android|ios] [--device|--emulator|--target <id>] '
      '[--env dev|release] [--release] [-- <flutter run args>]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final platform = args.positionals.contains('ios')
        ? DevicePlatform.ios
        : DevicePlatform.android;
    final device = await EmulatorControl(context: context).ensure(
      platform: platform,
      preference: _preference(args),
    );
    final envName = args.option(name: 'env').orElse(fallback: 'dev');
    final defines = _defines(envName);
    context.files.writeText(
      path: context.appDir.joinAll(['ios', 'Flutter', 'Secrets.xcconfig']),
      text: const SecretsXcconfig().render(defines: defines.values),
    );
    final outcome = await Shell(context: context).passThrough(
      command: CommandLine(
        executable: const Executable('flutter'),
        arguments: [
          'run',
          '-d',
          device.id.value,
          '--dart-define-from-file=../env/$envName.json',
          if (args.flag(name: 'release') == FlagState.on) '--release',
          ...args.afterSeparator,
        ],
        workingDirectory: context.appDir,
        environment: defines.childEnvironment,
      ),
    );
    return outcome.exitCode.value;
  }

  DevicePreference _preference(final ArgReader args) =>
      switch (args.option(name: 'target')) {
        OptionGiven(:final value) => ExactTarget(id: DeviceId(value)),
        OptionOmitted() => switch ((
          args.flag(name: 'device'),
          args.flag(name: 'emulator'),
        )) {
          (FlagState.on, FlagState.off) => const PreferPhysical(),
          (FlagState.off, FlagState.on) => const PreferEmulator(),
          (FlagState.off, FlagState.off) => const AnyDevice(),
          (FlagState.on, FlagState.on) => throw const CliFailure.usage(
            message: '--device and --emulator exclude each other',
          ),
        },
      };

  DartDefines _defines(final String envName) {
    final path = context.envDir.join('$envName.json');
    final text = switch (context.files.readText(path: path)) {
      TextRead(:final text) => text,
      NoSuchFile() => throw CliFailure.general(
        message: 'env/$envName.json not found',
      ),
    };
    return switch (DartDefines.parse(json: text)) {
      DartDefinesParsed(:final defines) => defines,
      DartDefinesRejected(:final reason) => throw CliFailure.general(
        message: 'env/$envName.json: $reason',
      ),
    };
  }
}
