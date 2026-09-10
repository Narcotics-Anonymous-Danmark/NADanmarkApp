import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/commands/release_check_command.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/release/android_release.dart';
import 'package:na_cli/src/release/release_options.dart';

final class ReleaseAndroidCommand extends Command<int> {
  ReleaseAndroidCommand({required this.context}) {
    addReleaseBuildOptions(parser: argParser);
  }

  final CliContext context;

  @override
  String get name => 'android';

  @override
  String get description => 'Build a signed Android app bundle.';

  @override
  String get invocation =>
      'na release android [--allow-dirty] [--dry-run] [--output dist]';

  @override
  Future<int> run() async {
    await AndroidRelease(context: context).build(
      options: releaseOptionsOf(
        args: ArgReader.of(command: this),
        context: context,
      ),
    );
    return 0;
  }
}

void addReleaseBuildOptions({required final ArgParser parser}) {
  parser
    ..addFlag(
      'allow-dirty',
      negatable: false,
      help: 'Do not require a clean git worktree.',
    )
    ..addFlag('dry-run', negatable: false, help: 'Print the plan only.')
    ..addOption('output', help: 'Directory for the artifact (default dist).');
}

ReleaseOptions releaseOptionsOf({
  required final ArgReader args,
  required final CliContext context,
}) => ReleaseOptions(
  dirtyPolicy: dirtyPolicyOf(flag: args.flag(name: 'allow-dirty')),
  execution: switch (args.flag(name: 'dry-run')) {
    FlagState.on => BuildExecution.dryRun,
    FlagState.off => BuildExecution.real,
  },
  outputDir: FilePath(
    args.option(name: 'output').orElse(fallback: 'dist'),
  ).resolveFrom(context.repoRoot),
);
