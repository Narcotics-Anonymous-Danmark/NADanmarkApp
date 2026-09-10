import 'package:args/command_runner.dart';
import 'package:na_cli/src/bootstrap/bootstrap_plan.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/host/inotify_limits.dart';
import 'package:na_cli/src/host/inotify_probe.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/steps/step.dart';
import 'package:na_cli/src/steps/step_runner.dart';
import 'package:na_cli/src/text/console_table.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/tool_presence.dart';

final class DoctorCommand extends Command<int> {
  DoctorCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Verify the environment without changing it.';

  @override
  Future<int> run() async {
    final platforms = ReleasePlatform.fromPositionals(
      positionals: const [],
      hostOs: context.hostOs,
    );
    final reports =
        await StepRunner(
          console: context.console,
          mode: StepMode.dryRun,
        ).checkAll(
          steps: BootstrapPlan(context: context).steps(platforms: platforms),
        );
    final inotify = await _inotify();
    final shell = Shell(context: context);
    await shell.passThrough(
      command: _command(const ['flutter', 'doctor', '-v']),
    );
    if (await shell.locate(executable: const Executable('patrol'))
        is ToolFound) {
      await shell.passThrough(command: _command(const ['patrol', 'doctor']));
    }
    final rows = [
      ...reports.map(
        (final r) => [
          r.name,
          if (r.state == StepState.satisfied) 'ok' else 'missing',
        ],
      ),
      ...inotify,
    ];
    context.console.out(
      line: ConsoleTable(
        headers: const ['Check', 'Status'],
        rows: rows,
      ).render(),
    );
    return rows.any((final row) => row[1] != 'ok') ? 1 : 0;
  }

  Future<List<List<String>>> _inotify() async {
    if (context.hostOs != HostOs.linux) {
      return const [];
    }
    final limits = await InotifyProbe(context: context).read();
    return switch (limits.verdict) {
      InotifyHealthy() => const [
        ['inotify limits', 'ok'],
      ],
      InotifyExhausted(:final reasons, :final fix) => [
        [
          'inotify limits',
          'blocker: ${[...reasons, ...fix].join('; ')}',
        ],
      ],
    };
  }

  CommandLine _command(final List<String> command) => CommandLine.at(
    executable: Executable(command.first),
    arguments: command.sublist(1),
    workingDirectory: context.repoRoot,
  );
}
