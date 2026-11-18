import 'package:na_cli/src/boundary/yaml_view.dart';
import 'package:na_cli/src/coverage/glob_pattern.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

extension type const Percent(double value) {
  String get display => value.toStringAsFixed(1);
}

final class CoveragePolicy {
  const CoveragePolicy({
    required this.mergedMinimum,
    required this.packageMinimums,
    required this.featureDefault,
    required this.adapterDefault,
    required this.excludePatterns,
  });

  final Percent mergedMinimum;
  final Map<PackageName, Percent> packageMinimums;
  final Percent featureDefault;
  final Percent adapterDefault;
  final List<GlobPattern> excludePatterns;

  static CoveragePolicyParse parse({required final String yamlText}) =>
      switch (YamlView.parse(text: yamlText)) {
        YamlMalformed(:final reason) => CoveragePolicyRejected(reason: reason),
        YamlParsed(:final view) => CoveragePolicyParsed(
          policy: CoveragePolicy(
            mergedMinimum: _percent(view: view, key: 'merged_minimum_percent'),
            featureDefault: _percent(
              view: view,
              key: 'feature_default_minimum_percent',
            ),
            adapterDefault: _percent(
              view: view,
              key: 'adapter_default_minimum_percent',
            ),
            packageMinimums: Map.unmodifiable({
              for (final entry
                  in view.numberEntries(key: 'package_minimum_percent').entries)
                PackageName(entry.key): Percent(entry.value),
            }),
            excludePatterns: List.unmodifiable(
              view.stringList(key: 'exclude_patterns').map(GlobPattern.new),
            ),
          ),
        ),
      };

  static Percent _percent({
    required final YamlView view,
    required final String key,
  }) => Percent(double.parse(view.text(key: key).orElse(fallback: '0')));

  PackageFloor floorFor({required final PackageName package}) {
    final explicit = packageMinimums.entries
        .where((final entry) => entry.key == package)
        .map((final entry) => FloorRequired(minimum: entry.value));
    if (explicit.isNotEmpty) {
      return explicit.first;
    }
    if (package.value.startsWith('feature_')) {
      return FloorRequired(minimum: featureDefault);
    }
    if (package.value.startsWith('adapter_')) {
      return FloorRequired(minimum: adapterDefault);
    }
    return const FloorNone();
  }

  FileInclusion inclusionOf({required final String path}) =>
      excludePatterns.any(
        (final pattern) => pattern.match(path: path) == GlobMatch.matches,
      )
      ? FileInclusion.excluded
      : FileInclusion.included;
}

enum FileInclusion { included, excluded }

sealed class PackageFloor {
  const PackageFloor();
}

final class FloorRequired extends PackageFloor {
  const FloorRequired({required this.minimum});

  final Percent minimum;
}

final class FloorNone extends PackageFloor {
  const FloorNone();
}

sealed class CoveragePolicyParse {
  const CoveragePolicyParse();
}

final class CoveragePolicyParsed extends CoveragePolicyParse {
  const CoveragePolicyParsed({required this.policy});

  final CoveragePolicy policy;
}

final class CoveragePolicyRejected extends CoveragePolicyParse {
  const CoveragePolicyRejected({required this.reason});

  final String reason;
}
