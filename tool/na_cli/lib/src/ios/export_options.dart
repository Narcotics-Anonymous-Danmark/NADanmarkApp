import 'package:na_cli/src/ios/provisioning_profile.dart';

extension type const SigningIdentity(String value) {}

final class ExportOptions {
  const ExportOptions({
    required this.teamId,
    required this.bundleId,
    required this.profileName,
    required this.signingCertificate,
  });

  final TeamId teamId;
  final BundleId bundleId;
  final String profileName;
  final SigningIdentity signingCertificate;

  static const String _doctype =
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
      '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">';

  String render() => [
    '<?xml version="1.0" encoding="UTF-8"?>',
    _doctype,
    '<plist version="1.0">',
    '<dict>',
    '  <key>method</key>',
    '  <string>app-store-connect</string>',
    '  <key>signingStyle</key>',
    '  <string>manual</string>',
    '  <key>teamID</key>',
    '  <string>${_escape(teamId.value)}</string>',
    '  <key>provisioningProfiles</key>',
    '  <dict>',
    '    <key>${_escape(bundleId.value)}</key>',
    '    <string>${_escape(profileName)}</string>',
    '  </dict>',
    '  <key>signingCertificate</key>',
    '  <string>${_escape(signingCertificate.value)}</string>',
    '  <key>uploadSymbols</key>',
    '  <true/>',
    '</dict>',
    '</plist>',
    '',
  ].join('\n');

  String _escape(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
