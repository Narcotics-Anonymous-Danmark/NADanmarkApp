import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/release/version_request.dart';
import 'package:na_cli/src/release/version_store.dart';

final class ReleaseVersionCommand extends Command<int> {
  ReleaseVersionCommand({required this.context}) {
    argParser
      ..addOption(
        'bump',
        help: 'Derive from the current version.',
        allowed: ['patch', 'minor', 'major'],
      )
      ..addOption('build', help: 'Build number within 1..999 (default 1).')
      ..addFlag('print', negatable: false, help: 'Show the current version.')
      ..addFlag('json', negatable: false, help: 'Print as JSON.')
      ..addFlag(
        'github-output',
        negatable: false,
        help:
            r'Append version=, build=, version_code=, tag= to $GITHUB_OUTPUT.',
      );
  }

  final CliContext context;

  @override
  String get name => 'version';

  @override
  String get description =>
      'Read or set app/pubspec.yaml version (the only writer).';

  @override
  String get invocation =>
      'na release version [x.y.z] [--bump patch|minor|major] [--build n] '
      '[--print] [--json] [--github-output]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final store = VersionStore(context: context);
    final current = store.read();
    final request = VersionRequest.from(
      positional: args.positionals.isEmpty
          ? const OptionOmitted()
          : OptionGiven(value: args.positionals.first),
      bump: args.option(name: 'bump'),
      build: args.option(name: 'build'),
    );
    final target = switch (request.resolve(current: current)) {
      VersionResolved(:final version) => version,
      VersionRequestRejected(:final reasons) => throw CliFailure.usage(
        message: reasons.join('; '),
      ),
    };
    switch (request) {
      case KeepCurrentVersion():
        break;
      case SetVersion() || BumpVersion():
        store.write(version: target);
        context.console.err(
          line: 'app/pubspec.yaml -> version: ${target.pubspecValue}',
        );
    }
    switch (args.flag(name: 'json')) {
      case FlagState.on:
        context.console.out(line: store.json(version: target));
      case FlagState.off:
        context.console.out(line: store.describe(version: target));
    }
    if (args.flag(name: 'github-output') == FlagState.on) {
      store.appendGithubOutput(version: target);
    }
    return 0;
  }
}
