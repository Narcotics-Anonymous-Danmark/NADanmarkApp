import 'package:na_cli/src/boundary/yaml_view.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

enum WorkspaceResolution { declared, missing }

enum LockFilePresence { present, absent }

final class PackageManifest {
  const PackageManifest({
    required this.name,
    required this.dependencies,
    required this.devDependencies,
    required this.resolution,
    required this.lockFile,
  });

  final PackageName name;
  final Set<String> dependencies;
  final Set<String> devDependencies;
  final WorkspaceResolution resolution;
  final LockFilePresence lockFile;

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
