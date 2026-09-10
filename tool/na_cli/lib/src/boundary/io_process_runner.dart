import 'dart:io';

import 'package:na_cli/src/ports/process_runner.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/process/process_outcome.dart';

final class IoProcessRunner implements ProcessRunner {
  const IoProcessRunner();

  @override
  Future<ProcessOutcome> capture({required final CommandLine command}) async {
    try {
      final result = await Process.run(
        command.executable.value,
        command.arguments,
        workingDirectory: command.workingDirectory.value,
        environment: command.environment,
      );
      final stdout = result.stdout.toString();
      final stderr = result.stderr.toString();
      if (result.exitCode == 0) {
        return ProcessSucceeded(stdout: stdout, stderr: stderr);
      }
      return ProcessFailed(
        code: ExitCode(result.exitCode),
        stdout: stdout,
        stderr: stderr,
      );
    } on ProcessException {
      return ProcessUnavailable(executable: command.executable);
    }
  }

  @override
  Future<ProcessOutcome> passThrough({
    required final CommandLine command,
  }) async {
    try {
      final process = await Process.start(
        command.executable.value,
        command.arguments,
        workingDirectory: command.workingDirectory.value,
        environment: command.environment,
        mode: ProcessStartMode.inheritStdio,
      );
      final code = await process.exitCode;
      if (code == 0) {
        return const ProcessSucceeded(stdout: '', stderr: '');
      }
      return ProcessFailed(code: ExitCode(code), stdout: '', stderr: '');
    } on ProcessException {
      return ProcessUnavailable(executable: command.executable);
    }
  }
}
