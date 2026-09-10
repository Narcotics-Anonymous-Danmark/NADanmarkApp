import 'package:na_cli/src/check/arb_parity.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/process/exit_code.dart';

final class ArbCheck {
  const ArbCheck({required this.context});

  final CliContext context;

  ExitCode run() {
    final l10n = context.repoRoot.joinAll([
      'packages',
      'core',
      'na_l10n',
      'lib',
      'l10n',
    ]);
    final english = _load(l10n.join('app_en.arb'));
    final danish = _load(l10n.join('app_da.arb'));
    final report = const ArbParity().compare(english: english, danish: danish);
    switch (report.verdict) {
      case ArbParityVerdict.inParity:
        context.console.out(
          line: 'arb: ${english.keys.length} keys in parity',
        );
        return ExitCode.success;
      case ArbParityVerdict.diverged:
        report.problems.forEach(_report);
        return ExitCode.failure;
    }
  }

  void _report(final String problem) =>
      context.console.err(line: 'arb: $problem');

  ArbDocument _load(final FilePath path) {
    final text = switch (context.files.readText(path: path)) {
      TextRead(:final text) => text,
      NoSuchFile() => throw CliFailure.general(
        message: 'missing ${path.relativeTo(context.repoRoot)}',
      ),
    };
    return switch (ArbDocument.parse(text: text)) {
      ArbParsed(:final document) => document,
      ArbRejected(:final reason) => throw CliFailure.general(
        message: '${path.basename}: $reason',
      ),
    };
  }
}
