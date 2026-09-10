@Tags(['unit'])
library;

import 'package:na_cli/src/check/layer_rules.dart';
import 'package:na_cli/src/check/package_manifest.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  PackageManifest manifest({
    required final String name,
    final List<String> deps = const [],
    final List<String> devDeps = const [],
    final String resolution = 'workspace',
    final LockFilePresence lock = LockFilePresence.absent,
  }) =>
      (PackageManifest.parse(
                pubspecText: aPubspec(
                  name: name,
                  dependencies: deps,
                  devDependencies: devDeps,
                  resolution: resolution,
                ),
                lockFile: lock,
              )
              as PackageManifestParsed)
          .manifest;

  List<String> reasons(final PackageManifest m) => const LayerRules()
      .violations(manifests: [m])
      .map((final v) => v.reason)
      .toList();

  test('a compliant workspace has no violations', () {
    final manifests = [
      manifest(name: 'na_kernel', deps: ['meta', 'collection']),
      manifest(name: 'na_ports', deps: ['na_kernel', 'flutter_riverpod']),
      manifest(
        name: 'na_design',
        deps: ['flutter', 'na_kernel', 'flutter_svg'],
      ),
      manifest(
        name: 'na_l10n',
        deps: ['flutter', 'flutter_localizations', 'intl'],
      ),
      manifest(name: 'na_testing', deps: ['na_kernel', 'flutter_test', 'test']),
      manifest(
        name: 'feature_meetings',
        deps: ['na_kernel', 'na_ports', 'go_router'],
      ),
      manifest(
        name: 'feature_home',
        deps: ['feature_meetings', 'feature_media_player'],
      ),
      manifest(name: 'adapter_bmlt', deps: ['na_kernel', 'na_ports', 'http']),
      manifest(name: 'na_app', deps: ['feature_meetings', 'adapter_bmlt']),
    ];
    expect(const LayerRules().violations(manifests: manifests), isEmpty);
  });

  test('kernel may only use sdk-level packages', () {
    expect(reasons(manifest(name: 'na_kernel', deps: ['http'])), [
      'may not depend on http',
    ]);
  });

  test('features never depend on adapters or unrelated features', () {
    expect(
      reasons(manifest(name: 'feature_x', deps: ['adapter_bmlt', 'feature_y'])),
      ['may not depend on adapter_bmlt', 'may not depend on feature_y'],
    );
  });

  test('adapters never depend on features, design or other adapters', () {
    expect(
      reasons(
        manifest(
          name: 'adapter_a',
          deps: ['feature_x', 'na_design', 'adapter_b'],
        ),
      ),
      hasLength(3),
    );
  });

  test('testing never depends on adapters or features', () {
    expect(
      reasons(manifest(name: 'na_testing', deps: ['adapter_a'])),
      hasLength(1),
    );
  });

  test('nobody depends on na_app, even in dev dependencies', () {
    expect(reasons(manifest(name: 'na_lints', devDeps: ['na_app'])), [
      'depends on na_app',
    ]);
  });

  test('members need workspace resolution and no own lock file', () {
    expect(
      reasons(
        manifest(
          name: 'na_lints',
          resolution: '',
          lock: LockFilePresence.present,
        ),
      ),
      ['lacks "resolution: workspace"', 'has its own pubspec.lock'],
    );
  });
}
