import 'dart:convert';

import 'package:na_cli/src/release/semantic_version.dart';
import 'package:na_cli/src/release/version.dart';

String aLcovFile({
  final String file = 'lib/a.dart',
  final Map<int, int> hits = const {1: 1, 2: 0},
}) => [
  'SF:$file',
  ...hits.entries.map((final e) => 'DA:${e.key},${e.value}'),
  'LF:${hits.length}',
  'LH:${hits.values.where((final v) => v > 0).length}',
  'end_of_record',
  '',
].join('\n');

String aPubspec({
  final String name = 'na_kernel',
  final List<String> dependencies = const [],
  final List<String> devDependencies = const [],
  final String resolution = 'workspace',
  final String version = '',
  final String constraint = '1.0.0',
}) => [
  'name: $name',
  if (version.isNotEmpty) 'version: $version',
  if (resolution.isNotEmpty) 'resolution: $resolution',
  'dependencies:',
  ...dependencies.map((final d) => '  $d: $constraint'),
  'dev_dependencies:',
  ...devDependencies.map((final d) => '  $d: $constraint'),
  '',
].join('\n');

String aRootPubspec({
  final List<String> members = const ['app', 'packages/core/na_kernel'],
}) => [
  'name: ws',
  'workspace:',
  ...members.map((final m) => '  - $m'),
  '',
].join('\n');

Map<String, Object> aDevice({
  final String id = 'emulator-5554',
  final String name = 'sdk gphone64',
  final String targetPlatform = 'android-x64',
  final bool emulator = true,
}) => {
  'id': id,
  'name': name,
  'targetPlatform': targetPlatform,
  'emulator': emulator,
};

String aDevicesJson({final List<Map<String, Object>> devices = const []}) =>
    jsonEncode(devices);

AppVersion anAppVersion({
  final int major = 2,
  final int minor = 0,
  final int patch = 0,
  final int build = 1,
}) => AppVersion(
  version: SemanticVersion(major: major, minor: minor, patch: patch),
  build: BuildNumber(build),
);

String aProvisioningProfilePlist({
  final String uuid = 'ABCD-1234',
  final String name = 'NA Danmark AppStore',
  final String expiration = '2030-01-01T00:00:00Z',
  final String team = 'TEAM123456',
  final String appId = 'TEAM123456.dk.nadanmark.ios.app',
}) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>DeveloperCertificates</key>
  <array><data>
  AAEC
  </data></array>
  <key>Entitlements</key>
  <dict>
    <key>application-identifier</key>
    <string>$appId</string>
    <key>get-task-allow</key>
    <false/>
  </dict>
  <key>ExpirationDate</key>
  <date>$expiration</date>
  <key>Name</key>
  <string>$name</string>
  <key>TeamIdentifier</key>
  <array>
    <string>$team</string>
  </array>
  <key>UUID</key>
  <string>$uuid</string>
  <key>Version</key>
  <integer>1</integer>
</dict>
</plist>
''';

String aServiceAccountJson({
  final String email = 'ci@project.iam.gserviceaccount.com',
  final String privateKey =
      r'-----BEGIN PRIVATE KEY-----\nAAA=\n-----END PRIVATE KEY-----\n',
}) =>
    '{"type":"service_account","client_email":"$email",'
    '"private_key":"$privateKey"}';

String aCoverageYaml({
  final int merged = 80,
  final Map<String, int> packages = const {'na_kernel': 95},
  final int feature = 95,
  final int adapter = 80,
  final List<String> excludes = const ['**/*.g.dart'],
}) => [
  'merged_minimum_percent: $merged',
  'package_minimum_percent:',
  ...packages.entries.map((final e) => '  ${e.key}: ${e.value}'),
  'feature_default_minimum_percent: $feature',
  'adapter_default_minimum_percent: $adapter',
  'exclude_patterns:',
  ...excludes.map((final e) => '  - "$e"'),
  '',
].join('\n');
