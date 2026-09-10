import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/check/format_check.dart';
import 'package:na_cli/src/cli_context.dart';

final class FormatCommand extends Command<int> {
  FormatCommand({required this.context}) {
    argParser.addFlag(
      'check',
      negatable: false,
      help: 'Fail when formatting would change files instead of writing.',
    );
  }

  final CliContext context;

  @override
  String get name => 'format';

  @override
  String get description => 'Format Dart sources (dart format, 80 columns).';

  @override
  String get invocation => 'na format [--check] [files...]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final mode = switch (args.flag(name: 'check')) {
      FlagState.on => FormatMode.check,
      FlagState.off => FormatMode.write,
    };
    final outcome = await FormatCheck(
      context: context,
    ).run(mode: mode, targets: args.rest);
    return outcome.value;
  }
}
