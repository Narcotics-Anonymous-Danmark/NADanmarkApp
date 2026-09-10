import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/coverage/coverage_markdown.dart';
import 'package:na_cli/src/coverage/coverage_merge.dart';
import 'package:na_cli/src/coverage/coverage_policy.dart';
import 'package:na_cli/src/coverage/coverage_report.dart';
import 'package:na_cli/src/coverage/lcov_writer.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/text/console_table.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/tool_presence.dart';
import 'package:na_cli/src/workspace/workspace_loader.dart';

final class CoverageCommand extends Command<int> {
  CoverageCommand({required this.context}) {
    argParser
      ..addFlag('merge', negatable: false, help: 'Merge coverage/*.lcov.info.')
      ..addFlag('html', negatable: false, help: 'Render HTML with genhtml.')
      ..addFlag(
        'check',
        negatable: false,
        help: 'Enforce coverage.yaml floors.',
      );
  }

  final CliContext context;

  @override
  String get name => 'coverage';

  @override
  String get description => 'Merge lcov files, render HTML, enforce floors.';

  @override
  String get invocation => 'na coverage [--merge] [--html] [--check]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    final members = WorkspaceLoader(context: context).members();
    final merged = CoverageMerge(context: context).merge(members: members);
    final mergedPath = context.coverageDir.join(CoverageMerge.mergedName);
    context.files.writeText(
      path: mergedPath,
      text: const LcovWriter().write(document: merged),
    );
    final report = CoverageReport.evaluate(
      merged: merged,
      policy: _policy(),
      members: members,
      repoRoot: context.repoRoot,
    );
    _publish(report);
    if (args.flag(name: 'html') == FlagState.on) {
      await _html(mergedPath);
    }
    if (args.flag(name: 'check') == FlagState.on &&
        report.offences.isNotEmpty) {
      context.console.err(
        line: ConsoleTable(
          headers: const ['Scope', 'Coverage', 'Minimum'],
          rows: report.offences
              .map(
                (final o) => [
                  o.scope,
                  '${o.actual.display}%',
                  '${o.minimum.display}%',
                ],
              )
              .toList(growable: false),
        ).render(),
      );
      return 1;
    }
    return 0;
  }

  void _publish(final CoverageReport report) {
    final markdown = const CoverageMarkdown().render(report: report);
    context.console.out(line: markdown);
    context.files.writeText(
      path: context.coverageDir.join('summary.md'),
      text: '$markdown\n',
    );
    switch (context.environment.lookup(
      key: const EnvKey('GITHUB_STEP_SUMMARY'),
    )) {
      case EnvSet(:final value):
        context.files.appendText(path: FilePath(value), text: '$markdown\n');
      case EnvUnset():
        break;
    }
  }

  Future<void> _html(final FilePath mergedPath) async {
    final shell = Shell(context: context);
    switch (await shell.locate(executable: const Executable('genhtml'))) {
      case ToolMissing():
        context.console.err(
          line: 'warning: genhtml (lcov) not found; skipping HTML',
        );
      case ToolFound():
        await shell.passThroughOrFail(
          command: CommandLine.at(
            executable: const Executable('genhtml'),
            arguments: [
              mergedPath.value,
              '-o',
              context.coverageDir.join('html').value,
            ],
            workingDirectory: context.repoRoot,
          ),
        );
    }
  }

  CoveragePolicy _policy() {
    final text = switch (context.files.readText(
      path: context.repoRoot.join('coverage.yaml'),
    )) {
      TextRead(:final text) => text,
      NoSuchFile() => throw const CliFailure.general(
        message: 'coverage.yaml not found at the repo root',
      ),
    };
    return switch (CoveragePolicy.parse(yamlText: text)) {
      CoveragePolicyParsed(:final policy) => policy,
      CoveragePolicyRejected(:final reason) => throw CliFailure.general(
        message: 'coverage.yaml: $reason',
      ),
    };
  }
}
