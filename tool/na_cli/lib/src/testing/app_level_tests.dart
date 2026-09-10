import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_options.dart';
import 'package:na_cli/src/testing/test_result.dart';
import 'package:na_cli/src/testing/test_tool.dart';
import 'package:na_cli/src/tools/shell.dart';

sealed class E2eMode {
  const E2eMode();
}

final class E2eSuite extends E2eMode {
  const E2eSuite();
}

final class E2eDevelop extends E2eMode {
  const E2eDevelop({required this.target});

  final String target;
}

final class AppLevelTests {
  const AppLevelTests({required this.context});

  final CliContext context;

  Future<TestResult> acceptance({required final TestOptions options}) async {
    final lcov = context.coverageDir.join('na_app.acceptance.lcov.info');
    final outcome = await Shell(context: context).passThrough(
      command: CommandLine.at(
        executable: const Executable('flutter'),
        arguments: [
          'test',
          'test_acceptance',
          ...options.passThroughArguments(
            tool: TestTool.flutter,
            level: TestLevel.acceptance,
          ),
          ...switch (options.coverage) {
            CoverageCollection.off => const <String>[],
            CoverageCollection.on => [
              '--coverage',
              '--coverage-path',
              lcov.value,
            ],
          },
        ],
        workingDirectory: context.appDir,
      ),
    );
    return _result(label: 'na_app:acceptance', outcome: outcome);
  }

  Future<TestResult> e2e({
    required final DevicePlatform platform,
    required final OptionValue device,
    required final E2eMode mode,
    required final CoverageCollection coverage,
  }) async {
    final deviceArgs = switch (device) {
      OptionGiven(:final value) => ['-d', value],
      OptionOmitted() => const <String>[],
    };
    final outcome = await Shell(context: context).passThrough(
      command: CommandLine.at(
        executable: const Executable('patrol'),
        arguments: switch (mode) {
          E2eDevelop(:final target) => ['develop', '-t', target, ...deviceArgs],
          E2eSuite() => [
            'test',
            ...switch (coverage) {
              CoverageCollection.on => const ['--coverage'],
              CoverageCollection.off => const <String>[],
            },
            ...deviceArgs,
            '--dart-define-from-file=../env/test.json',
          ],
        },
        workingDirectory: context.appDir,
      ),
    );
    _collectPatrolCoverage(platform: platform, coverage: coverage);
    return _result(label: 'na_app:e2e-${platform.name}', outcome: outcome);
  }

  void _collectPatrolCoverage({
    required final DevicePlatform platform,
    required final CoverageCollection coverage,
  }) {
    final source = context.appDir.joinAll(['coverage', 'patrol_lcov.info']);
    if (coverage == CoverageCollection.off ||
        context.files.status(path: source) != PathStatus.file) {
      return;
    }
    context.files.copyFile(
      from: source,
      to: context.coverageDir.join('e2e-${platform.name}.lcov.info'),
    );
  }

  TestResult _result({
    required final String label,
    required final ProcessOutcome outcome,
  }) => switch (outcome) {
    ProcessSucceeded() || ProcessFailed() => TestResult.fromOutcome(
      label: label,
      outcome: outcome,
    ),
    ProcessUnavailable(:final executable) => throw CliFailure.general(
      message: '${executable.value} is not installed',
    ),
  };
}
