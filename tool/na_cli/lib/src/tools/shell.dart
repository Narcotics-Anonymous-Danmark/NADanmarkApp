import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/tools/tool_presence.dart';

final class Shell {
  const Shell({required this.context});

  final CliContext context;

  Future<ProcessOutcome> capture({required final CommandLine command}) =>
      context.processes.capture(command: command);

  Future<ProcessOutcome> passThrough({required final CommandLine command}) {
    context.console.out(line: r'$ ' + command.display);
    return context.processes.passThrough(command: command);
  }

  Future<void> passThroughOrFail({required final CommandLine command}) async {
    final outcome = await passThrough(command: command);
    _failOn(outcome: outcome, command: command);
  }

  Future<String> captureOrFail({required final CommandLine command}) async {
    final outcome = await capture(command: command);
    _failOn(outcome: outcome, command: command);
    return outcome.stdout;
  }

  Future<ToolPresence> locate({required final Executable executable}) async {
    final outcome = await capture(
      command: CommandLine.at(
        executable: const Executable('which'),
        arguments: [executable.value],
        workingDirectory: context.repoRoot,
      ),
    );
    return switch (outcome) {
      ProcessSucceeded(:final stdout) => ToolFound(
        path: FilePath(stdout.trim()),
      ),
      ProcessFailed() || ProcessUnavailable() => ToolMissing(
        executable: executable,
      ),
    };
  }

  void _failOn({
    required final ProcessOutcome outcome,
    required final CommandLine command,
  }) {
    switch (outcome) {
      case ProcessSucceeded():
        return;
      case ProcessFailed(:final code):
        throw CliFailure(
          message:
              '${command.display} failed (exit ${code.value})'
              '${outcome.stderr.isEmpty ? '' : '\n${outcome.stderr.trim()}'}',
          exitCode: code,
        );
      case ProcessUnavailable(:final executable):
        throw CliFailure.general(
          message: '${executable.value} is not installed or not on PATH',
        );
    }
  }
}
