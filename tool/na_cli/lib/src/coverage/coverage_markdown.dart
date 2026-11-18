import 'package:na_cli/src/coverage/coverage_report.dart';
import 'package:na_cli/src/text/markdown_table.dart';

final class CoverageMarkdown {
  const CoverageMarkdown();

  String render({required final CoverageReport report}) {
    final table = MarkdownTable(
      headers: const ['Package', 'Lines', 'Coverage', 'Status'],
      rows: [
        for (final coverage in report.packages)
          [
            coverage.package.value,
            '${coverage.linesHit}/${coverage.linesFound}',
            '${coverage.percent.display}%',
            _status(report: report, scope: coverage.package.value),
          ],
        [
          '**merged**',
          '',
          '${report.total.display}%',
          _status(report: report, scope: 'merged'),
        ],
      ],
    );
    return '## Coverage\n\n${table.render()}';
  }

  String _status({
    required final CoverageReport report,
    required final String scope,
  }) => report.offences.any((final offence) => offence.scope == scope)
      ? 'below floor'
      : 'ok';
}
