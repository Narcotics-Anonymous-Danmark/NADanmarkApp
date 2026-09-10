import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/check/analyze_check.dart';
import 'package:na_cli/src/check/arb_check.dart';
import 'package:na_cli/src/check/commit_message_check.dart';
import 'package:na_cli/src/check/deps_check.dart';
import 'package:na_cli/src/check/format_check.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/process/exit_code.dart';

enum CheckKind { format, analyze, arb, deps, commitMsg }

final class CheckCommand extends Command<int> {
  CheckCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Format, analyze, custom lints, ARB parity and dependency layers.';

  @override
  String get invocation =>
      'na check [format|analyze|arb|deps|commit-msg <file-or-message>]';

  @override
  Future<int> run() async {
    final positionals = ArgReader.of(command: this).positionals;
    if (positionals.isEmpty) {
      return _runAll();
    }
    final kind = _kind(positionals.first);
    return switch (kind) {
      CheckKind.format => (await _format()).value,
      CheckKind.analyze => (await _analyze()).value,
      CheckKind.arb => (await _arb()).value,
      CheckKind.deps => (await _deps()).value,
      CheckKind.commitMsg => (await _commitMessage(positionals.skip(1))).value,
    };
  }

  Future<int> _runAll() async {
    final results = [
      await _format(),
      await _analyze(),
      await _arb(),
      await _deps(),
    ];
    return results.any((final code) => code != ExitCode.success) ? 1 : 0;
  }

  Future<ExitCode> _format() => FormatCheck(
    context: context,
  ).run(mode: FormatMode.check, targets: const []);

  Future<ExitCode> _analyze() => AnalyzeCheck(context: context).run();

  Future<ExitCode> _arb() async => ArbCheck(context: context).run();

  Future<ExitCode> _deps() async => DepsCheck(context: context).run();

  Future<ExitCode> _commitMessage(final Iterable<String> rest) async {
    if (rest.isEmpty) {
      throw const CliFailure.usage(
        message: 'check commit-msg needs a file path or a message',
      );
    }
    return CommitMessageCheck(context: context).run(argument: rest.first);
  }

  CheckKind _kind(final String word) {
    if (word == 'commit-msg') {
      return CheckKind.commitMsg;
    }
    final matches = CheckKind.values.where((final kind) => kind.name == word);
    if (matches.isEmpty) {
      throw CliFailure.usage(message: 'unknown check "$word"');
    }
    return matches.first;
  }
}
