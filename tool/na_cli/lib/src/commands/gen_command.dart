import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/gen/l10n_generator.dart';

enum GenTarget { l10n, all }

final class GenCommand extends Command<int> {
  GenCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'gen';

  @override
  String get description => 'Run code generation (l10n).';

  @override
  String get invocation => 'na gen [l10n|all]';

  @override
  Future<int> run() async {
    final positionals = ArgReader.of(command: this).positionals;
    final target = positionals.isEmpty ? 'all' : positionals.first;
    final matches = GenTarget.values.where((final t) => t.name == target);
    if (matches.isEmpty) {
      throw CliFailure.usage(message: 'unknown gen target "$target"');
    }
    final generator = L10nGenerator(context: context);
    switch (matches.first) {
      case GenTarget.l10n:
        await generator.generate();
      case GenTarget.all:
        await generator.pubGet();
        await generator.generate();
    }
    return 0;
  }
}
