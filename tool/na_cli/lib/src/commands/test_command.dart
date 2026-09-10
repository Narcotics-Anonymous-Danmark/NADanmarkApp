import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/testing/app_level_tests.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_options.dart';
import 'package:na_cli/src/testing/test_plan.dart';
import 'package:na_cli/src/testing/test_result.dart';
import 'package:na_cli/src/testing/test_session.dart';
import 'package:na_cli/src/text/console_table.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class TestCommand extends Command<int> {
  TestCommand({required this.context}) {
    argParser
      ..addFlag('coverage', negatable: false, help: 'Collect lcov coverage.')
      ..addOption('package', help: 'Only this workspace package.')
      ..addOption('device', help: 'Device id for e2e.')
      ..addFlag('develop', negatable: false, help: 'patrol develop for e2e.')
      ..addOption('target', help: 'Test file for --develop.')
      ..addOption('file', help: 'Run only this test file (owning package).')
      ..addOption('name', help: 'Only tests whose name contains this text.')
      ..addFlag(
        'update-goldens',
        negatable: false,
        help: 'Pass --update-goldens to flutter test (widget, acceptance).',
      );
  }

  final CliContext context;

  @override
  String get name => 'test';

  @override
  String get description => 'Run tests per level across the workspace.';

  @override
  String get invocation =>
      'na test [unit|widget|acceptance|e2e|all] [android|ios] [--coverage] '
      '[--package <name>] [--file <path>] [--name <text>] [--update-goldens] '
      '[--device <id>] [--develop --target <file>]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final platformWords = args.positionals.where(
      (final word) => word == 'android' || word == 'ios',
    );
    final platform = platformWords.contains('ios')
        ? DevicePlatform.ios
        : DevicePlatform.android;
    final levels = TestLevel.fromWords(
      words: args.positionals
          .where((final word) => !platformWords.contains(word))
          .toList(growable: false),
    );
    final options = TestOptions(
      coverage: switch (args.flag(name: 'coverage')) {
        FlagState.on => CoverageCollection.on,
        FlagState.off => CoverageCollection.off,
      },
      nameFilter: switch (args.option(name: 'name')) {
        OptionOmitted() => const AnyName(),
        OptionGiven(:final value) => PlainName(text: value),
      },
      goldens: switch (args.flag(name: 'update-goldens')) {
        FlagState.on => GoldenPolicy.update,
        FlagState.off => GoldenPolicy.keep,
      },
    );
    final scope = switch (args.option(name: 'file')) {
      OptionOmitted() => const WholeSuite(),
      OptionGiven(:final value) => SingleFile(
        path: FilePath(value).resolveFrom(context.repoRoot),
      ),
    };
    context.files.ensureDirectory(path: context.coverageDir);
    final session = TestSession(context: context);
    final jobs = const TestPlan().jobs(
      candidates: session.candidates(),
      levels: levels,
      filter: switch (args.option(name: 'package')) {
        OptionOmitted() => const AllPackages(),
        OptionGiven(:final value) => OnlyPackage(name: PackageName(value)),
      },
      scope: scope,
      options: options,
      coverageDir: context.coverageDir,
      repoRoot: context.repoRoot,
    );
    final appTests = AppLevelTests(context: context);
    final results = [
      ...await session.runJobs(jobs: jobs),
      if (levels.contains(TestLevel.acceptance))
        await appTests.acceptance(options: options),
      if (levels.contains(TestLevel.e2e))
        await appTests.e2e(
          platform: platform,
          device: args.option(name: 'device'),
          mode: _e2eMode(args),
          coverage: options.coverage,
        ),
    ];
    context.console.out(
      line: ConsoleTable(
        headers: const ['Suite', 'Result'],
        rows: results
            .map((final r) => [r.label, r.verdict.name])
            .toList(growable: false),
      ).render(),
    );
    return results.any((final r) => r.verdict == TestVerdict.failed) ? 1 : 0;
  }

  E2eMode _e2eMode(final ArgReader args) =>
      switch (args.flag(name: 'develop')) {
        FlagState.off => const E2eSuite(),
        FlagState.on => switch (args.option(name: 'target')) {
          OptionGiven(:final value) => E2eDevelop(target: value),
          OptionOmitted() => throw const CliFailure.usage(
            message: '--develop needs --target <file>',
          ),
        },
      };
}
