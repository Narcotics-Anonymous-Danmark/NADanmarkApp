import 'package:na_cli/src/check/package_layer.dart';
import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class DependencyViolation {
  const DependencyViolation({required this.package, required this.reason});

  final PackageName package;
  final String reason;
}

enum DependencyPermission { allowed, forbidden }

final class LayerRules {
  const LayerRules();

  static const Set<String> _featureBridges = {
    'feature_meetings',
    'feature_media_player',
  };

  List<DependencyViolation> violations({
    required final List<PackageManifest> manifests,
  }) => List.unmodifiable(
    manifests.expand((final manifest) => _violationsOf(manifest: manifest)),
  );

  Iterable<DependencyViolation> _violationsOf({
    required final PackageManifest manifest,
  }) {
    final layer = PackageLayer.of(name: manifest.name);
    final all = {...manifest.dependencies, ...manifest.devDependencies};
    return [
      if (manifest.resolution == WorkspaceResolution.missing)
        _violation(manifest: manifest, reason: 'lacks "resolution: workspace"'),
      if (manifest.lockFile == LockFilePresence.present)
        _violation(manifest: manifest, reason: 'has its own pubspec.lock'),
      if (all.contains('na_app') && layer != PackageLayer.app)
        _violation(manifest: manifest, reason: 'depends on na_app'),
      ...manifest.dependencies
          .where(
            (final dep) =>
                _permission(layer: layer, self: manifest.name, dep: dep) ==
                DependencyPermission.forbidden,
          )
          .map(
            (final dep) => _violation(
              manifest: manifest,
              reason: 'may not depend on $dep',
            ),
          ),
    ];
  }

  DependencyViolation _violation({
    required final PackageManifest manifest,
    required final String reason,
  }) => DependencyViolation(package: manifest.name, reason: reason);

  DependencyPermission _permission({
    required final PackageLayer layer,
    required final PackageName self,
    required final String dep,
  }) => switch (layer) {
    PackageLayer.kernel => _only(
      dep: dep,
      allowed: const {'meta', 'collection', 'intl'},
    ),
    PackageLayer.ports => _only(
      dep: dep,
      allowed: const {'na_kernel', 'riverpod', 'flutter_riverpod', 'meta'},
    ),
    PackageLayer.design => _only(
      dep: dep,
      allowed: const {
        'flutter',
        'flutter_svg',
        'na_kernel',
        'phosphor_flutter',
        'meta',
      },
    ),
    PackageLayer.l10n => _only(
      dep: dep,
      allowed: const {'flutter', 'flutter_localizations', 'intl', 'na_kernel'},
    ),
    PackageLayer.testing => _never(
      dep: dep,
      prefixes: const ['adapter_', 'feature_'],
      except: const {},
    ),
    PackageLayer.feature => _never(
      dep: dep,
      prefixes: const ['adapter_', 'feature_'],
      except: _featureBridges,
    ),
    PackageLayer.adapter => _never(
      dep: dep,
      prefixes: const ['feature_', 'na_design', 'adapter_'],
      except: {self.value},
    ),
    PackageLayer.app || PackageLayer.tool => DependencyPermission.allowed,
  };

  DependencyPermission _only({
    required final String dep,
    required final Set<String> allowed,
  }) => allowed.contains(dep)
      ? DependencyPermission.allowed
      : DependencyPermission.forbidden;

  DependencyPermission _never({
    required final String dep,
    required final List<String> prefixes,
    required final Set<String> except,
  }) => prefixes.any(dep.startsWith) && !except.contains(dep)
      ? DependencyPermission.forbidden
      : DependencyPermission.allowed;
}
