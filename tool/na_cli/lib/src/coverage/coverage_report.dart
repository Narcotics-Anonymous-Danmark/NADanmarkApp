import 'package:collection/collection.dart';
import 'package:na_cli/src/coverage/coverage_policy.dart';
import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class PackageCoverage {
  const PackageCoverage({
    required this.package,
    required this.percent,
    required this.linesHit,
    required this.linesFound,
  });

  final PackageName package;
  final Percent percent;
  final int linesHit;
  final int linesFound;
}

final class CoverageOffence {
  const CoverageOffence({
    required this.scope,
    required this.actual,
    required this.minimum,
  });

  final String scope;
  final Percent actual;
  final Percent minimum;
}

final class CoverageReport {
  const CoverageReport({
    required this.total,
    required this.packages,
    required this.offences,
  });

  factory CoverageReport.evaluate({
    required final LcovDocument merged,
    required final CoveragePolicy policy,
    required final List<WorkspaceMember> members,
    required final FilePath repoRoot,
  }) {
    final included = merged.select(
      selection: (final record) => switch (policy.inclusionOf(
        path: record.file.value,
      )) {
        FileInclusion.included => RecordSelection.keep,
        FileInclusion.excluded => RecordSelection.drop,
      },
    );
    final packages = members
        .expand(
          (final member) => _packageCoverage(
            document: included,
            member: member,
            repoRoot: repoRoot,
          ),
        )
        .sortedBy((final coverage) => coverage.package.value);
    final total = Percent(included.percent);
    final offences = [
      if (total.value < policy.mergedMinimum.value)
        CoverageOffence(
          scope: 'merged',
          actual: total,
          minimum: policy.mergedMinimum,
        ),
      ...packages.expand(
        (final coverage) => switch (policy.floorFor(
          package: coverage.package,
        )) {
          FloorNone() => const <CoverageOffence>[],
          FloorRequired(:final minimum) =>
            coverage.percent.value < minimum.value
                ? [
                    CoverageOffence(
                      scope: coverage.package.value,
                      actual: coverage.percent,
                      minimum: minimum,
                    ),
                  ]
                : const <CoverageOffence>[],
        },
      ),
    ];
    return CoverageReport(
      total: total,
      packages: List.unmodifiable(packages),
      offences: List.unmodifiable(offences),
    );
  }

  final Percent total;
  final List<PackageCoverage> packages;
  final List<CoverageOffence> offences;

  static List<PackageCoverage> _packageCoverage({
    required final LcovDocument document,
    required final WorkspaceMember member,
    required final FilePath repoRoot,
  }) {
    final prefix = '${member.libDirectory.relativeTo(repoRoot)}/';
    final owned = document.select(
      selection: (final record) => record.file.value.startsWith(prefix)
          ? RecordSelection.keep
          : RecordSelection.drop,
    );
    if (owned.records.isEmpty) {
      return const [];
    }
    return [
      PackageCoverage(
        package: member.name,
        percent: Percent(owned.percent),
        linesHit: owned.linesHit,
        linesFound: owned.linesFound,
      ),
    ];
  }
}
