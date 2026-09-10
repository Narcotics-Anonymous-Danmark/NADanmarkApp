import 'package:args/command_runner.dart';
import 'package:na_cli/src/bootstrap/android_steps.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/devices/device_selector.dart';
import 'package:na_cli/src/devices/emulator_control.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:na_cli/src/steps/step_runner.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

enum EmulatorAction { start, stop, create }

final class EmulatorCommand extends Command<int> {
  EmulatorCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'emulator';

  @override
  String get description => 'Start, stop or create the project Android AVD.';

  @override
  String get invocation => 'na emulator start|stop|create';

  @override
  Future<int> run() async {
    final positionals = ArgReader.of(command: this).positionals;
    final word = positionals.isEmpty ? 'start' : positionals.first;
    final matches = EmulatorAction.values.where((final a) => a.name == word);
    if (matches.isEmpty) {
      throw CliFailure.usage(message: 'unknown emulator action "$word"');
    }
    final control = EmulatorControl(context: context);
    switch (matches.first) {
      case EmulatorAction.start:
        final device = await control.ensure(
          platform: DevicePlatform.android,
          preference: const PreferEmulator(),
        );
        context.console.out(line: 'emulator ready: ${device.id.value}');
      case EmulatorAction.stop:
        await control.stop();
      case EmulatorAction.create:
        await StepRunner(console: context.console, mode: StepMode.apply).runAll(
          steps: [
            AndroidSteps(
              context: context,
              settings: ToolchainSettings.load(context: context),
            ).avd(),
          ],
        );
    }
    return 0;
  }
}
