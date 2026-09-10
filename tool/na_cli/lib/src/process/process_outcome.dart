import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/exit_code.dart';

sealed class ProcessOutcome {
  const ProcessOutcome({required this.stdout, required this.stderr});

  final String stdout;
  final String stderr;

  ExitCode get exitCode => switch (this) {
    ProcessSucceeded() => ExitCode.success,
    ProcessFailed(:final code) => code,
    ProcessUnavailable() => ExitCode.unavailable,
  };

  String get combinedOutput => '$stdout$stderr';
}

final class ProcessSucceeded extends ProcessOutcome {
  const ProcessSucceeded({required super.stdout, required super.stderr});
}

final class ProcessFailed extends ProcessOutcome {
  const ProcessFailed({
    required this.code,
    required super.stdout,
    required super.stderr,
  });

  final ExitCode code;
}

final class ProcessUnavailable extends ProcessOutcome {
  const ProcessUnavailable({required this.executable})
    : super(stdout: '', stderr: '');

  final Executable executable;
}
