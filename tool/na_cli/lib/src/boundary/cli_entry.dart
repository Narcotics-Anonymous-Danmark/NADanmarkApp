import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/host_os_detector.dart';
import 'package:na_cli/src/boundary/http_client_transport.dart';
import 'package:na_cli/src/boundary/io_console.dart';
import 'package:na_cli/src/boundary/io_environment.dart';
import 'package:na_cli/src/boundary/io_file_system.dart';
import 'package:na_cli/src/boundary/io_process_runner.dart';
import 'package:na_cli/src/boundary/io_sleeper.dart';
import 'package:na_cli/src/boundary/repo_root_locator.dart';
import 'package:na_cli/src/boundary/secure_secret_generator.dart';
import 'package:na_cli/src/boundary/system_clock.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/runner/na_command_runner.dart';

Future<void> runNaCli(final List<String> arguments) async {
  final context = CliContext(
    repoRoot: const RepoRootLocator().locate(),
    hostOs: const HostOsDetector().detect(),
    processes: const IoProcessRunner(),
    files: const IoFileSystem(),
    environment: const IoEnvironment(),
    console: const IoConsole(),
    clock: const SystemClock(),
    sleeper: const IoSleeper(),
    secrets: const SecureSecretGenerator(),
    http: const HttpClientTransport(),
  );
  final code = await runWithContext(context: context, arguments: arguments);
  exitCode = code.value;
}

Future<ExitCode> runWithContext({
  required final CliContext context,
  required final List<String> arguments,
}) async {
  final runner = NaCommandRunner(context: context);
  try {
    final result = await runner.run(arguments);
    return ExitCode(result ?? 0);
  } on UsageException catch (error) {
    context.console.err(line: error.toString());
    return ExitCode.usage;
  } on CliFailure catch (failure) {
    context.console.err(line: 'error: ${failure.message}');
    return failure.exitCode;
  }
}
