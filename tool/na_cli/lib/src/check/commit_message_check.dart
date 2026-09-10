import 'package:na_cli/src/check/conventional_commit.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/process/exit_code.dart';

final class CommitMessageCheck {
  const CommitMessageCheck({required this.context});

  final CliContext context;

  ExitCode run({required final String argument}) {
    final message = switch (context.files.readText(
      path: FilePath(argument).resolveFrom(context.repoRoot),
    )) {
      TextRead(:final text) => text,
      NoSuchFile() => argument,
    };
    switch (const ConventionalCommit().check(message: message)) {
      case CommitMessageAccepted(:final subject):
        context.console.out(line: 'commit message ok: $subject');
        return ExitCode.success;
      case CommitMessageRejected(:final reason):
        context.console.err(line: 'error: $reason');
        return ExitCode.failure;
    }
  }
}
