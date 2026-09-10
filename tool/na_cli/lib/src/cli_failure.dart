import 'package:na_cli/src/process/exit_code.dart';

final class CliFailure implements Exception {
  const CliFailure({required this.message, required this.exitCode});

  const CliFailure.usage({required this.message}) : exitCode = ExitCode.usage;

  const CliFailure.general({required this.message})
    : exitCode = ExitCode.failure;

  final String message;
  final ExitCode exitCode;

  @override
  String toString() => message;
}
