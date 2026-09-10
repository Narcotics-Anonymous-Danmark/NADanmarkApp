import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/tools/shell.dart';

final class L10nGenerator {
  const L10nGenerator({required this.context});

  final CliContext context;

  Future<void> pubGet() => Shell(context: context).passThroughOrFail(
    command: CommandLine.at(
      executable: const Executable('flutter'),
      arguments: const ['pub', 'get'],
      workingDirectory: context.repoRoot,
    ),
  );

  Future<void> generate() async {
    final l10nDir = context.repoRoot.joinAll(['packages', 'core', 'na_l10n']);
    await Shell(context: context).passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('flutter'),
        arguments: const ['gen-l10n'],
        workingDirectory: l10nDir,
      ),
    );
    final untranslated = context.files.readText(
      path: l10nDir.join('untranslated.json'),
    );
    switch (untranslated) {
      case NoSuchFile():
        return;
      case TextRead(:final text):
        final body = text.replaceAll(RegExp(r'\s'), '');
        if (body.isNotEmpty && body != '{}') {
          throw CliFailure.general(
            message: 'untranslated messages remain:\n${text.trim()}',
          );
        }
    }
  }
}
