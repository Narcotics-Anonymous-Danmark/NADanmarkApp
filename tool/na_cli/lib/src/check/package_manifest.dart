import 'package:na_cli/src/boundary/yaml_view.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

enum WorkspaceResolution { declared, missing }

enum LockFilePresence { present, absent }

extension type const PackageVersion(String value) {
  static const PackageVersion internal = PackageVersion('0.0.0');
}

sealed class DependencySpec {
  const DependencySpec({required this.name});

  final String name;

  static DependencySpec from({
    required final String name,
    required final String spec,
  }) {
    if (spec == 'path:') {
      return PathDependency(name: name);
    }
    if (spec == 'sdk:') {
      return SdkDependency(name: name);
    }
    if (_exact.hasMatch(spec)) {
      return PinnedDependency(name: name, version: spec);
    }
    return UnpinnedDependency(name: name, constraint: spec);
  }

  static final RegExp _exact = RegExp(
    r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.+-]+)?$',
  );
}

final class PinnedDependency extends DependencySpec {
  const PinnedDependency({required super.name, required this.version});

  final String version;
}

final class UnpinnedDependency extends DependencySpec {
  const UnpinnedDependency({required super.name, required this.constraint});

  final String constraint;
}

final class PathDependency extends DependencySpec {
  const PathDependency({required super.name});
}

final class SdkDependency extends DependencySpec {
  const SdkDependency({required super.name});
}

final class PackageManifest {
  const PackageManifest({
    required this.name,
    required this.dependencies,
    required this.devDependencies,
    required this.resolution,
    required this.lockFile,
    required this.version,
    required this.specs,
  });

  final PackageName name;
  final Set<String> dependencies;
  final Set<String> devDependencies;
  final WorkspaceResolution resolution;
  final LockFilePresence lockFile;
  final PackageVersion version;
  final List<DependencySpec> specs;

  static PackageManifestParse parse({
    required final String pubspecText,
    required final LockFilePresence lockFile,
  }) => switch (YamlView.parse(text: pubspecText)) {
    YamlMalformed(:final reason) => PackageManifestRejected(reason: reason),
    YamlParsed(:final view) => PackageManifestParsed(
      manifest: PackageManifest(
        name: PackageName(view.text(key: 'name').orElse(fallback: '?')),
        dependencies: Set.unmodifiable(
          view.section(key: 'dependencies').keys,
        ),
        devDependencies: Set.unmodifiable(
          view.section(key: 'dev_dependencies').keys,
        ),
        resolution:
            view.text(key: 'resolution').orElse(fallback: '') == 'workspace'
            ? WorkspaceResolution.declared
            : WorkspaceResolution.missing,
        lockFile: lockFile,
        version: PackageVersion(view.text(key: 'version').orElse(fallback: '')),
        specs: List.unmodifiable([
          for (final section in const ['dependencies', 'dev_dependencies'])
            ...view
                .dependencySpecs(key: section)
                .entries
                .map(
                  (final entry) =>
                      DependencySpec.from(name: entry.key, spec: entry.value),
                ),
        ]),
      ),
    ),
  };
}

sealed class PackageManifestParse {
  const PackageManifestParse();
}

final class PackageManifestParsed extends PackageManifestParse {
  const PackageManifestParsed({required this.manifest});

  final PackageManifest manifest;
}

final class PackageManifestRejected extends PackageManifestParse {
  const PackageManifestRejected({required this.reason});

  final String reason;
}
