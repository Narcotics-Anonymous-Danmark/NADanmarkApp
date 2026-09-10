import 'package:args/command_runner.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/commands/publish_play_command.dart';
import 'package:na_cli/src/commands/publish_testflight_command.dart';

final class PublishCommand extends Command<int> {
  PublishCommand({required final CliContext context}) {
    addSubcommand(PublishPlayCommand(context: context));
    addSubcommand(PublishTestflightCommand(context: context));
  }

  @override
  String get name => 'publish';

  @override
  String get description =>
      'Upload store artifacts to internal testing (CI, or --yes locally).';
}
