@Tags(['unit'])
library;

import 'package:na_cli/src/ios/export_options.dart';
import 'package:na_cli/src/ios/provisioning_profile.dart';
import 'package:na_cli/src/plist/plist_reader.dart';
import 'package:na_cli/src/plist/plist_value.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  const reader = PlistReader();

  test('reads dicts, arrays, strings, dates, data, integers and booleans', () {
    final plist = reader.read(xml: aProvisioningProfilePlist());
    expect(plist.at(key: 'UUID').text, 'ABCD-1234');
    expect(
      plist.at(key: 'TeamIdentifier').index(position: 0).text,
      'TEAM123456',
    );
    expect(plist.at(key: 'Version'), isA<PlistInteger>());
    expect(
      plist.at(key: 'Entitlements').at(key: 'get-task-allow'),
      const PlistBool(value: PlistTruth.no),
    );
    expect(
      plist.at(key: 'DeveloperCertificates').index(position: 0).text,
      'AAEC',
    );
    expect(plist.at(key: 'ExpirationDate'), isA<PlistDate>());
    expect(plist.at(key: 'Nope'), isA<PlistMissing>());
    expect(
      plist.at(key: 'TeamIdentifier').index(position: 5),
      isA<PlistMissing>(),
    );
  });

  test('unescapes xml entities and handles empty strings', () {
    final plist = reader.read(
      xml: [
        '<plist><dict><key>a</key><string>x &amp; y</string>',
        '<key>b</key><string></string><key>c</key><string/></dict></plist>',
      ].join(),
    );
    expect(plist.at(key: 'a').text, 'x & y');
    expect(plist.at(key: 'b').text, '');
    expect(plist.at(key: 'c').text, '');
  });

  test('without a plist element yields missing', () {
    expect(reader.read(xml: '<dict/>'), isA<PlistMissing>());
  });

  group('provisioning profile', () {
    final now = DateTime.utc(2026, 9, 10);
    ProvisioningProfile profile({
      final String expiration = '2030-01-01T00:00:00Z',
    }) => ProvisioningProfile.fromPlist(
      plist: reader.read(
        xml: aProvisioningProfilePlist(expiration: expiration),
      ),
    );

    test('a matching, unexpired profile has no problems', () {
      expect(
        profile().problems(
          expectedTeam: const TeamId('TEAM123456'),
          expectedBundle: BundleId.iosApp,
          now: now,
        ),
        isEmpty,
      );
    });

    test('reports expiry, team and bundle mismatches', () {
      final problems = profile(expiration: '2020-01-01T00:00:00Z').problems(
        expectedTeam: const TeamId('OTHER'),
        expectedBundle: const BundleId('dk.other.app'),
        now: now,
      );
      expect(problems, hasLength(3));
    });
  });

  test('export options plist renders the manual signing settings', () {
    final xml = const ExportOptions(
      teamId: TeamId('TEAM123456'),
      bundleId: BundleId.iosApp,
      profileName: 'NA & Friends',
      signingCertificate: SigningIdentity(
        'Apple Distribution: NA (TEAM123456)',
      ),
    ).render();
    final parsed = reader.read(xml: xml);
    expect(parsed.at(key: 'method').text, 'app-store-connect');
    expect(parsed.at(key: 'signingStyle').text, 'manual');
    expect(parsed.at(key: 'teamID').text, 'TEAM123456');
    expect(
      parsed
          .at(key: 'provisioningProfiles')
          .at(key: 'dk.nadanmark.ios.app')
          .text,
      'NA & Friends',
    );
    expect(
      parsed.at(key: 'signingCertificate').text,
      'Apple Distribution: NA (TEAM123456)',
    );
  });
}
