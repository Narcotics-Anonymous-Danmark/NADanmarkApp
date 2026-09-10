import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/tools/shell.dart';

enum FormatMode { check, write }

final class FormatCheck {
  const FormatCheck({required this.context});

  final CliContext context;

  Future<ExitCode> run({
    required final FormatMode mode,
    required final List<String> targets,
  }) async {
    final dartTargets = targets.where((final t) => t.endsWith('.dart'));
    if (targets.isNotEmpty && dartTargets.isEmpty) {
      return ExitCode.success;
    }
    final outcome = await Shell(context: context).passThrough(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: [
          'format',
          '--line-length=80',
          ...switch (mode) {
            FormatMode.check => const [
              '--set-exit-if-changed',
              '--output=none',
            ],
            FormatMode.write => const <String>[],
          },
          if (dartTargets.isEmpty) '.' else ...dartTargets,
        ],
        workingDirectory: context.repoRoot,
      ),
    );
    return outcome.exitCode;
  }
}
