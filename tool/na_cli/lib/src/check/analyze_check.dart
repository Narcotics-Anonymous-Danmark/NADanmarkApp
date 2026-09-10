import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/tools/shell.dart';

final class AnalyzeCheck {
  const AnalyzeCheck({required this.context});

  final CliContext context;

  Future<ExitCode> run() async {
    final shell = Shell(context: context);
    final analyze = await shell.passThrough(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: const ['analyze', '--fatal-infos', '--fatal-warnings', '.'],
        workingDirectory: context.repoRoot,
      ),
    );
    final lint = await _customLint(shell);
    return [analyze, lint].any((final o) => o is! ProcessSucceeded)
        ? ExitCode.failure
        : ExitCode.success;
  }

  Future<ProcessOutcome> _customLint(final Shell shell) async {
    final probe = await shell.capture(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: const ['pub', 'deps', '--json'],
        workingDirectory: context.repoRoot,
      ),
    );
    if (!probe.stdout.contains('"custom_lint"')) {
      context.console.err(
        line: 'warning: custom_lint is not resolvable at the root; skipping',
      );
      return const ProcessSucceeded(stdout: '', stderr: '');
    }
    return shell.passThrough(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: const ['run', 'custom_lint', '--fatal-infos'],
        workingDirectory: context.repoRoot,
      ),
    );
  }
}
