import 'package:args/command_runner.dart';
import 'package:na_cli/src/bootstrap/bootstrap_plan.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/host/inotify_limits.dart';
import 'package:na_cli/src/host/inotify_probe.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/steps/step_runner.dart';

final class BootstrapCommand extends Command<int> {
  BootstrapCommand({required this.context}) {
    argParser
      ..addFlag('dry-run', negatable: false, help: 'Print the steps only.')
      ..addFlag('force', negatable: false, help: 'Run every step.');
  }

  final CliContext context;

  @override
  String get name => 'bootstrap';

  @override
  String get description => 'Install the toolchain idempotently.';

  @override
  String get invocation => 'na bootstrap [android|ios] [--dry-run] [--force]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final platforms = ReleasePlatform.fromPositionals(
      positionals: args.positionals,
      hostOs: context.hostOs,
    );
    await _inotifyAdvice();
    final mode = switch ((
      args.flag(name: 'dry-run'),
      args.flag(name: 'force'),
    )) {
      (FlagState.on, FlagState.on) ||
      (FlagState.on, FlagState.off) => StepMode.dryRun,
      (FlagState.off, FlagState.on) => StepMode.force,
      (FlagState.off, FlagState.off) => StepMode.apply,
    };
    await StepRunner(console: context.console, mode: mode).runAll(
      steps: BootstrapPlan(context: context).steps(platforms: platforms),
    );
    return 0;
  }

  Future<void> _inotifyAdvice() async {
    if (context.hostOs != HostOs.linux) {
      return;
    }
    final limits = await InotifyProbe(context: context).read();
    switch (limits.verdict) {
      case InotifyHealthy():
        return;
      case InotifyExhausted(:final reasons, :final fix):
        context.console.err(
          line: [
            'warning: inotify limits will break the Dart analysis server:',
            ...reasons.map((final r) => '  - $r'),
            '  fix:',
            ...fix.map((final f) => '    $f'),
          ].join('\n'),
        );
    }
  }
}
