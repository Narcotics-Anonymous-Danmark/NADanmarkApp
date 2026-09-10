import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/testing/test_job.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_options.dart';
import 'package:na_cli/src/testing/test_tool.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

enum TestDirectory { present, absent }

final class TestCandidate {
  const TestCandidate({
    required this.member,
    required this.manifest,
    required this.testDirectory,
  });

  final WorkspaceMember member;
  final PackageManifest manifest;
  final TestDirectory testDirectory;

  TestTool get tool =>
      manifest.dependencies.contains('flutter') ||
          manifest.devDependencies.contains('flutter_test')
      ? TestTool.flutter
      : TestTool.dart;
}

sealed class PackageFilter {
  const PackageFilter();
}

final class AllPackages extends PackageFilter {
  const AllPackages();
}

final class OnlyPackage extends PackageFilter {
  const OnlyPackage({required this.name});

  final PackageName name;
}

final class TestPlan {
  const TestPlan();

  List<TestJob> jobs({
    required final List<TestCandidate> candidates,
    required final List<TestLevel> levels,
    required final PackageFilter filter,
    required final TestScope scope,
    required final TestOptions options,
    required final FilePath coverageDir,
    required final FilePath repoRoot,
  }) => List.unmodifiable(switch (scope) {
    WholeSuite() => _suiteJobs(
      candidates: candidates,
      levels: levels,
      filter: filter,
      options: options,
      coverageDir: coverageDir,
      repoRoot: repoRoot,
    ),
    SingleFile(:final path) => _fileJobs(
      candidates: candidates,
      levels: levels,
      path: path,
      options: options,
      coverageDir: coverageDir,
      repoRoot: repoRoot,
    ),
  });

  Iterable<TestJob> _suiteJobs({
    required final List<TestCandidate> candidates,
    required final List<TestLevel> levels,
    required final PackageFilter filter,
    required final TestOptions options,
    required final FilePath coverageDir,
    required final FilePath repoRoot,
  }) => levels
      .where(
        (final level) => level == TestLevel.unit || level == TestLevel.widget,
      )
      .expand(
        (final level) => candidates
            .where((final c) => c.testDirectory == TestDirectory.present)
            .where(
              (final c) =>
                  _selection(candidate: c, filter: filter) ==
                  Selection.included,
            )
            .where(
              (final c) =>
                  level == TestLevel.unit || c.tool == TestTool.flutter,
            )
            .map(
              (final c) => TestJob(
                member: c.member,
                level: level,
                tool: c.tool,
                scope: const WholeSuite(),
                options: options,
                coverageDir: coverageDir,
                repoRoot: repoRoot,
              ),
            ),
      );

  Iterable<TestJob> _fileJobs({
    required final List<TestCandidate> candidates,
    required final List<TestLevel> levels,
    required final FilePath path,
    required final TestOptions options,
    required final FilePath coverageDir,
    required final FilePath repoRoot,
  }) => candidates
      .where(
        (final c) =>
            path.containment(root: c.member.directory) ==
            PathContainment.inside,
      )
      .map(
        (final c) => TestJob(
          member: c.member,
          level: levels.first,
          tool: c.tool,
          scope: SingleFile(path: path),
          options: options,
          coverageDir: coverageDir,
          repoRoot: repoRoot,
        ),
      );

  Selection _selection({
    required final TestCandidate candidate,
    required final PackageFilter filter,
  }) => switch (filter) {
    AllPackages() => Selection.included,
    OnlyPackage(:final name) =>
      candidate.member.name == name ? Selection.included : Selection.excluded,
  };
}

enum Selection { included, excluded }
