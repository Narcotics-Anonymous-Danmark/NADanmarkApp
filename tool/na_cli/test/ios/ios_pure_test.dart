@Tags(['unit'])
library;

import 'package:na_cli/src/android/key_alias.dart';
import 'package:na_cli/src/android/key_properties.dart';
import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/ios/ipa_verification.dart';
import 'package:na_cli/src/ios/secrets_xcconfig.dart';
import 'package:na_cli/src/ios/signing_identities.dart';
import 'package:na_cli/src/testflight/build_processing.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  test('finds an Apple Distribution identity in the security listing', () {
    const listing = '''
  1) ABCDEF0123456789 "Apple Development: Someone (ABC)"
  2) 0123456789ABCDEF "Apple Distribution: NA Danmark (TEAM123456)"
     2 valid identities found
''';
    final found = const SigningIdentities().distributionIdentity(
      listing: listing,
    );
    expect(
      (found as IdentityFound).identity.value,
      'Apple Distribution: NA Danmark (TEAM123456)',
    );
    expect(
      const SigningIdentities().distributionIdentity(
        listing: '0 valid identities',
      ),
      isA<IdentityMissing>(),
    );
  });

  test('ipa verification compares versions and signature presence', () {
    const facts = IpaFacts(
      shortVersion: '2.0.0\n',
      bundleVersion: '1\n',
      codeResourcesPresent: CodeResources.present,
    );
    expect(
      const IpaVerification().problems(facts: facts, expected: anAppVersion()),
      isEmpty,
    );
    expect(
      const IpaVerification().problems(
        facts: const IpaFacts(
          shortVersion: '1.9.0',
          bundleVersion: '2',
          codeResourcesPresent: CodeResources.missing,
        ),
        expected: anAppVersion(),
      ),
      hasLength(3),
    );
  });

  test('secrets xcconfig only carries the maps key', () {
    final text = const SecretsXcconfig().render(
      defines: const {'GOOGLE_MAPS_API_KEY': 'abc', 'NA_API_BASIC_AUTH': 'u:p'},
    );
    expect(text, 'GOOGLE_MAPS_API_KEY = abc\n');
  });

  test('key.properties renders the four keys with the conventional alias', () {
    const properties = KeyProperties(
      storeFile: FilePath('/repo/.na-release/upload.keystore'),
      storePassword: 'sp',
      keyAlias: ConventionalAlias(),
      keyPassword: 'kp',
    );
    expect(
      properties.render(),
      'storeFile=/repo/.na-release/upload.keystore\nstorePassword=sp\n'
      'keyAlias=nadanmarkapp\nkeyPassword=kp\n',
    );
    expect(const ProvidedAlias(alias: 'x').value, 'x');
  });

  test('dart defines expose the maps key to child processes', () {
    final defines =
        (DartDefines.parse(
                  json: '{"GOOGLE_MAPS_API_KEY":"k","NA_API_BASIC_AUTH":" "}',
                )
                as DartDefinesParsed)
            .defines;
    expect(defines.childEnvironment, {'GOOGLE_MAPS_API_KEY': 'k'});
    expect(defines.missingNonEmpty(keys: const ['NA_API_BASIC_AUTH', 'X']), [
      'NA_API_BASIC_AUTH',
      'X',
    ]);
    expect(DartDefines.parse(json: '[]'), isA<DartDefinesRejected>());
  });

  test('build processing states', () {
    expect(
      BuildProcessing.fromState(buildId: '1', state: 'VALID'),
      isA<BuildValid>(),
    );
    expect(
      BuildProcessing.fromState(buildId: '1', state: 'INVALID'),
      isA<BuildRejected>(),
    );
    expect(
      BuildProcessing.fromState(buildId: '1', state: 'FAILED'),
      isA<BuildRejected>(),
    );
    expect(
      BuildProcessing.fromState(buildId: '1', state: 'PROCESSING'),
      isA<BuildStillProcessing>(),
    );
  });
}
