import 'package:na_cli/src/check/layer_rules.dart';
import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class PinRules {
  const PinRules();

  static const PackageName app = PackageName('na_app');

  List<DependencyViolation> violations({
    required final List<PackageManifest> manifests,
  }) => List.unmodifiable(
    manifests.expand((final manifest) => _violationsOf(manifest: manifest)),
  );

  Iterable<DependencyViolation> _violationsOf({
    required final PackageManifest manifest,
  }) => [
    if (manifest.name != app && manifest.version != PackageVersion.internal)
      DependencyViolation(
        package: manifest.name,
        reason:
            'version is "${manifest.version.value}"; internal packages are '
            '${PackageVersion.internal.value}',
      ),
    ...manifest.specs.whereType<UnpinnedDependency>().map(
      (final dependency) => DependencyViolation(
        package: manifest.name,
        reason:
            '${dependency.name} is not pinned to an exact version '
            '("${dependency.constraint}")',
      ),
    ),
  ];
}
