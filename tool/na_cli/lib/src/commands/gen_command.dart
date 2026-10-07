import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/gen/json_generator.dart';
import 'package:na_cli/src/gen/l10n_generator.dart';

enum GenTarget { l10n, json, all }

final class GenCommand extends Command<int> {
  GenCommand({required this.context});

  final CliContext context;

  @override
  String get name => 'gen';

  @override
  String get description =>
      'Run code generation (l10n from ARB, JSON part files from DTOs).';

  @override
  String get invocation => 'na gen [l10n|json|all]';

  @override
  Future<int> run() async {
    final positionals = ArgReader.of(command: this).positionals;
    final target = positionals.isEmpty ? 'all' : positionals.first;
    final matches = GenTarget.values.where((final t) => t.name == target);
    if (matches.isEmpty) {
      throw CliFailure.usage(message: 'unknown gen target "$target"');
    }
    final generator = L10nGenerator(context: context);
    final json = JsonGenerator(context: context);
    switch (matches.first) {
      case GenTarget.l10n:
        await generator.generate();
      case GenTarget.json:
        await json.generate();
      case GenTarget.all:
        await generator.pubGet();
        await json.generate();
        await generator.generate();
    }
    return 0;
  }
}
