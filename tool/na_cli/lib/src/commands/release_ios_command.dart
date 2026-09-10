import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/commands/release_android_command.dart';
import 'package:na_cli/src/release/ios_release.dart';

final class ReleaseIosCommand extends Command<int> {
  ReleaseIosCommand({required this.context}) {
    addReleaseBuildOptions(parser: argParser);
  }

  final CliContext context;

  @override
  String get name => 'ios';

  @override
  String get description => 'Build a signed iOS ipa (macOS only).';

  @override
  String get invocation =>
      'na release ios [--allow-dirty] [--dry-run] [--output dist]';

  @override
  Future<int> run() async {
    await IosRelease(context: context).build(
      options: releaseOptionsOf(
        args: ArgReader.of(command: this),
        context: context,
      ),
    );
    return 0;
  }
}
