@Tags(['unit'])
library;

import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/check/pin_rules.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

PackageManifest manifestOf({required final String pubspec}) =>
    (PackageManifest.parse(
              pubspecText: pubspec,
              lockFile: LockFilePresence.absent,
            )
            as PackageManifestParsed)
        .manifest;

List<String> reasonsOf({required final String pubspec}) => const PinRules()
    .violations(manifests: [manifestOf(pubspec: pubspec)])
    .map((final violation) => violation.reason)
    .toList();

void main() {
  test('exact versions, path and sdk dependencies pass', () {
    expect(
      reasonsOf(
        pubspec: [
          'name: na_kernel',
          'version: 0.0.0',
          'dependencies:',
          '  meta: 1.17.0',
          '  dio: 5.11.1+2',
          '  flutter:',
          '    sdk: flutter',
          '  na_ports:',
          '    path: ../na_ports',
          '',
        ].join('\n'),
      ),
      isEmpty,
    );
  });

  test('ranges and any are rejected in both sections', () {
    expect(
      reasonsOf(
        pubspec: aPubspec(
          version: '0.0.0',
          dependencies: ['meta'],
          devDependencies: ['test'],
          constraint: '^1.0.0',
        ),
      ),
      [
        'meta is not pinned to an exact version ("^1.0.0")',
        'test is not pinned to an exact version ("^1.0.0")',
      ],
    );
    expect(
      reasonsOf(
        pubspec: aPubspec(
          version: '0.0.0',
          dependencies: ['meta'],
          constraint: 'any',
        ),
      ),
      ['meta is not pinned to an exact version ("any")'],
    );
  });

  test('internal packages must be version 0.0.0 and the app may not', () {
    expect(reasonsOf(pubspec: aPubspec(version: '0.1.0')), [
      'version is "0.1.0"; internal packages are 0.0.0',
    ]);
    expect(
      reasonsOf(
        pubspec: aPubspec(name: 'na_app', version: '2.0.0+1'),
      ),
      isEmpty,
    );
  });

  test('a git or hosted map source is not a pin', () {
    expect(
      reasonsOf(
        pubspec: [
          'name: na_kernel',
          'version: 0.0.0',
          'dependencies:',
          '  thing:',
          '    git: https://example.com/thing.git',
          '',
        ].join('\n'),
      ),
      ['thing is not pinned to an exact version ("source:git")'],
    );
  });
}
