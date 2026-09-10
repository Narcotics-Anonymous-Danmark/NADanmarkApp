import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/process/process_outcome.dart';

enum TestVerdict { passed, failed, skipped }

final class TestResult {
  const TestResult({
    required this.label,
    required this.verdict,
    required this.exitCode,
  });

  factory TestResult.fromOutcome({
    required final String label,
    required final ProcessOutcome outcome,
  }) => TestResult(
    label: label,
    verdict: const SuiteVerdict().of(outcome: outcome),
    exitCode: outcome.exitCode,
  );

  final String label;
  final TestVerdict verdict;
  final ExitCode exitCode;
}

final class SuiteVerdict {
  const SuiteVerdict();

  static const ExitCode noTestsRan = ExitCode(79);

  static const List<String> _skipMarkers = [
    'No tests match the requested tag selectors',
    'No tests ran',
  ];

  TestVerdict of({required final ProcessOutcome outcome}) => switch (outcome) {
    ProcessSucceeded() => switch (_presence(outcome)) {
      TestPresence.some => TestVerdict.passed,
      TestPresence.none => TestVerdict.skipped,
    },
    ProcessFailed(:final code) =>
      code == noTestsRan || _presence(outcome) == TestPresence.none
          ? TestVerdict.skipped
          : TestVerdict.failed,
    ProcessUnavailable() => TestVerdict.failed,
  };

  TestPresence _presence(final ProcessOutcome outcome) =>
      _skipMarkers.any(outcome.combinedOutput.contains)
      ? TestPresence.none
      : TestPresence.some;
}

enum TestPresence { some, none }
