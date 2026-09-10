import 'package:na_cli/src/plist/plist_value.dart';

extension type const TeamId(String value) {}

extension type const BundleId(String value) {
  static const BundleId iosApp = BundleId('dk.nadanmark.ios.app');
}

extension type const ProfileUuid(String value) {}

final class ProvisioningProfile {
  const ProvisioningProfile({
    required this.uuid,
    required this.name,
    required this.expiresAt,
    required this.teamIdentifier,
    required this.applicationIdentifier,
  });

  factory ProvisioningProfile.fromPlist({required final PlistValue plist}) =>
      ProvisioningProfile(
        uuid: ProfileUuid(plist.at(key: 'UUID').text),
        name: plist.at(key: 'Name').text,
        expiresAt:
            DateTime.tryParse(plist.at(key: 'ExpirationDate').text) ??
            DateTime.utc(1970),
        teamIdentifier: TeamId(
          plist.at(key: 'TeamIdentifier').index(position: 0).text,
        ),
        applicationIdentifier: plist
            .at(key: 'Entitlements')
            .at(key: 'application-identifier')
            .text,
      );

  final ProfileUuid uuid;
  final String name;
  final DateTime expiresAt;
  final TeamId teamIdentifier;
  final String applicationIdentifier;

  List<String> problems({
    required final TeamId expectedTeam,
    required final BundleId expectedBundle,
    required final DateTime now,
  }) => List.unmodifiable([
    if (uuid.value.isEmpty) 'profile has no UUID',
    if (name.isEmpty) 'profile has no Name',
    if (!expiresAt.isAfter(now)) 'profile expired at $expiresAt',
    if (teamIdentifier != expectedTeam)
      'profile team ${teamIdentifier.value} differs from ${expectedTeam.value}',
    if (!applicationIdentifier.endsWith(expectedBundle.value))
      _wrongBundle(expected: expectedBundle),
  ]);

  String _wrongBundle({required final BundleId expected}) =>
      'profile application-identifier "$applicationIdentifier" is not for '
      '${expected.value}';
}
