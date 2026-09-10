import 'package:args/command_runner.dart';
import 'package:na_cli/src/check/analyze_check.dart';
import 'package:na_cli/src/cli_context.dart';

final class AnalyzeCommand extends Command<int> {
  AnalyzeCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Run flutter analyze (fatal infos and warnings) and custom_lint.';

  @override
  Future<int> run() async {
    final outcome = await AnalyzeCheck(context: context).run();
    return outcome.value;
  }
}
