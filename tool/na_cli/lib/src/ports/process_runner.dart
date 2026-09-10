import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/process_outcome.dart';

abstract interface class ProcessRunner {
  Future<ProcessOutcome> capture({required CommandLine command});

  Future<ProcessOutcome> passThrough({required CommandLine command});
}
