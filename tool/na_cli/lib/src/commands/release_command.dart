import 'package:args/command_runner.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/commands/release_android_command.dart';
import 'package:na_cli/src/commands/release_check_command.dart';
import 'package:na_cli/src/commands/release_ios_command.dart';
import 'package:na_cli/src/commands/release_version_command.dart';

final class ReleaseCommand extends Command<int> {
  ReleaseCommand({required final CliContext context}) {
    addSubcommand(ReleaseVersionCommand(context: context));
    addSubcommand(ReleaseCheckCommand(context: context));
    addSubcommand(ReleaseAndroidCommand(context: context));
    addSubcommand(ReleaseIosCommand(context: context));
  }

  @override
  String get name => 'release';

  @override
  String get description => 'Version numbers and signed store builds.';
}
