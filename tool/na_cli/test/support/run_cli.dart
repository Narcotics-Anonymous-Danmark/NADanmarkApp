import 'package:na_cli/src/boundary/cli_entry.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/process/exit_code.dart';

Future<ExitCode> runCli({
  required final CliContext context,
  required final List<String> arguments,
}) => runWithContext(context: context, arguments: arguments);

const String appPubspecPath = '/repo/app/pubspec.yaml';
