import 'package:na_cli/src/ports/process_runner.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/process/process_outcome.dart';

final class ScriptedResponse {
  ScriptedResponse({
    required this.match,
    required final List<ProcessOutcome> outcomes,
  }) : _outcomes = [...outcomes];

  final String match;
  final List<ProcessOutcome> _outcomes;

  ProcessOutcome next() =>
      _outcomes.length > 1 ? _outcomes.removeAt(0) : _outcomes.first;
}

ProcessOutcome anOutcome({final String stdout = '', final int exitCode = 0}) =>
    exitCode == 0
    ? ProcessSucceeded(stdout: stdout, stderr: '')
    : ProcessFailed(code: ExitCode(exitCode), stdout: stdout, stderr: '');

ScriptedResponse whenRun({
  required final String match,
  final String stdout = '',
  final int exitCode = 0,
}) => ScriptedResponse(
  match: match,
  outcomes: [anOutcome(stdout: stdout, exitCode: exitCode)],
);

ScriptedResponse whenRunSequence({
  required final String match,
  required final List<ProcessOutcome> outcomes,
}) => ScriptedResponse(match: match, outcomes: outcomes);

ScriptedResponse whenMissing({required final String match}) =>
    whenRun(match: match, exitCode: 1);

final class ProcessRunnerMimic implements ProcessRunner {
  ProcessRunnerMimic({final List<ScriptedResponse> responses = const []})
    : _responses = responses;

  final List<ScriptedResponse> _responses;
  final List<CommandLine> captured = [];
  final List<CommandLine> passedThrough = [];

  List<String> get displays =>
      [...captured, ...passedThrough].map((final c) => c.display).toList();

  List<String> get passedThroughDisplays =>
      passedThrough.map((final c) => c.display).toList();

  @override
  Future<ProcessOutcome> capture({required final CommandLine command}) async {
    captured.add(command);
    return _respond(command);
  }

  @override
  Future<ProcessOutcome> passThrough({
    required final CommandLine command,
  }) async {
    passedThrough.add(command);
    return _respond(command);
  }

  ProcessOutcome _respond(final CommandLine command) {
    final display = command.display;
    final hits = _responses.where((final r) => display.startsWith(r.match));
    return hits.isEmpty
        ? const ProcessSucceeded(stdout: '', stderr: '')
        : hits.first.next();
  }
}
