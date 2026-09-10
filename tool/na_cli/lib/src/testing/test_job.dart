import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_options.dart';
import 'package:na_cli/src/testing/test_tool.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class TestJob {
  const TestJob({
    required this.member,
    required this.level,
    required this.tool,
    required this.scope,
    required this.options,
    required this.coverageDir,
    required this.repoRoot,
  });

  final WorkspaceMember member;
  final TestLevel level;
  final TestTool tool;
  final TestScope scope;
  final TestOptions options;
  final FilePath coverageDir;
  final FilePath repoRoot;

  FilePath get _packageConfig =>
      repoRoot.joinAll(['.dart_tool', 'package_config.json']);

  String get label => '${member.name.value}:${level.name}';

  FilePath get lcovPath =>
      coverageDir.join('${member.name.value}.${level.name}.lcov.info');

  FilePath get rawCoverageDir =>
      member.directory.joinAll(['coverage', 'raw', level.name]);

  List<String> get _selection => switch (scope) {
    WholeSuite() => ['--tags', level.name],
    SingleFile(:final path) => [path.relativeTo(member.directory)],
  };

  List<String> get _passThrough =>
      options.passThroughArguments(tool: tool, level: level);

  List<CommandLine> get commands => switch (tool) {
    TestTool.flutter => [
      CommandLine.at(
        executable: const Executable('flutter'),
        arguments: [
          'test',
          ..._selection,
          ..._passThrough,
          ...switch (options.coverage) {
            CoverageCollection.off => const <String>[],
            CoverageCollection.on => [
              '--coverage',
              '--coverage-path',
              lcovPath.value,
            ],
          },
        ],
        workingDirectory: member.directory,
      ),
    ],
    TestTool.dart => [
      CommandLine.at(
        executable: const Executable('dart'),
        arguments: [
          'test',
          ..._selection,
          ..._passThrough,
          ...switch (options.coverage) {
            CoverageCollection.off => const <String>[],
            CoverageCollection.on => ['--coverage=${rawCoverageDir.value}'],
          },
        ],
        workingDirectory: member.directory,
      ),
      ...switch (options.coverage) {
        CoverageCollection.off => const <CommandLine>[],
        CoverageCollection.on => [
          CommandLine.at(
            executable: const Executable('dart'),
            arguments: [
              'run',
              'coverage:format_coverage',
              '--lcov',
              '--packages=${_packageConfig.value}',
              '--report-on=${member.libDirectory.value}',
              '--in=${rawCoverageDir.value}',
              '-o',
              lcovPath.value,
            ],
            workingDirectory: repoRoot,
          ),
        ],
      },
    ],
  };
}
