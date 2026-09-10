import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/release/release_blockers.dart';
import 'package:na_cli/src/release/release_check.dart';
import 'package:na_cli/src/release/release_platform.dart';

final class ReleaseCheckCommand extends Command<int> {
  ReleaseCheckCommand({required this.context}) {
    argParser.addFlag(
      'allow-dirty',
      negatable: false,
      help: 'Do not require a clean git worktree.',
    );
  }

  final CliContext context;

  @override
  String get name => 'check';

  @override
  String get description => 'Verify everything a store release needs.';

  @override
  String get invocation => 'na release check [android|ios] [--allow-dirty]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    await ReleaseCheck(context: context).assertReady(
      platforms: ReleasePlatform.fromPositionals(
        positionals: args.positionals,
        hostOs: context.hostOs,
      ),
      dirtyPolicy: dirtyPolicyOf(flag: args.flag(name: 'allow-dirty')),
    );
    return 0;
  }
}

DirtyPolicy dirtyPolicyOf({required final FlagState flag}) => switch (flag) {
  FlagState.on => DirtyPolicy.allow,
  FlagState.off => DirtyPolicy.forbid,
};
