import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/testing/bounded_pool.dart';
import 'package:na_cli/src/testing/test_job.dart';
import 'package:na_cli/src/testing/test_plan.dart';
import 'package:na_cli/src/testing/test_result.dart';
import 'package:na_cli/src/workspace/workspace_loader.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class TestSession {
  const TestSession({required this.context});

  final CliContext context;

  List<TestCandidate> candidates() => List.unmodifiable(
    WorkspaceLoader(context: context).members().expand(_candidate),
  );

  Future<List<TestResult>> runJobs({required final List<TestJob> jobs}) =>
      const BoundedPool(width: 4).map(items: jobs, action: _runJob);

  Future<TestResult> _runJob(final TestJob job) async {
    context.console.out(line: '[test] ${job.label}');
    for (final command in job.commands) {
      final outcome = await context.processes.capture(command: command);
      final output = outcome.combinedOutput.trim();
      if (output.isNotEmpty) {
        context.console.out(line: output);
      }
      final result = TestResult.fromOutcome(
        label: job.label,
        outcome: outcome,
      );
      if (result.verdict != TestVerdict.passed) {
        return result;
      }
    }
    return TestResult(
      label: job.label,
      verdict: TestVerdict.passed,
      exitCode: ExitCode.success,
    );
  }

  List<TestCandidate> _candidate(final WorkspaceMember member) {
    final text = switch (context.files.readText(path: member.pubspecPath)) {
      TextRead(:final text) => text,
      NoSuchFile() => '',
    };
    final parsed = PackageManifest.parse(
      pubspecText: text,
      lockFile: LockFilePresence.absent,
    );
    return switch (parsed) {
      PackageManifestRejected() => const [],
      PackageManifestParsed(:final manifest) => [
        TestCandidate(
          member: member,
          manifest: manifest,
          testDirectory: switch (context.files.status(
            path: member.testDirectory,
          )) {
            PathStatus.directory => TestDirectory.present,
            PathStatus.file || PathStatus.missing => TestDirectory.absent,
          },
        ),
      ],
    };
  }
}
