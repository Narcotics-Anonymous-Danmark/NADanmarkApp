import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/release/version.dart';

enum WorktreeState { clean, dirty }

enum DirtyPolicy { forbid, allow }

sealed class ReleaseDefines {
  const ReleaseDefines();
}

final class ReleaseDefinesLoaded extends ReleaseDefines {
  const ReleaseDefinesLoaded({required this.defines});

  final DartDefines defines;
}

final class ReleaseDefinesUnavailable extends ReleaseDefines {
  const ReleaseDefinesUnavailable({required this.reason});

  final String reason;
}

final class ReleaseFacts {
  const ReleaseFacts({
    required this.worktree,
    required this.dirtyPolicy,
    required this.defines,
    required this.pubspecVersion,
    required this.environment,
    required this.toolsOnPath,
    required this.hostOs,
  });

  final WorktreeState worktree;
  final DirtyPolicy dirtyPolicy;
  final ReleaseDefines defines;
  final AppVersionParse pubspecVersion;
  final Map<String, String> environment;
  final Set<String> toolsOnPath;
  final HostOs hostOs;
}

final class ReleaseBlockers {
  const ReleaseBlockers();

  static const List<String> androidSecrets = [
    'ANDROID_KEYSTORE_BASE64',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_PASSWORD',
  ];

  static const List<String> iosSecrets = [
    'IOS_DIST_CERT_BASE64',
    'IOS_DIST_CERT_PASSWORD',
    'IOS_TEAM_ID',
    'IOS_PROVISIONING_PROFILE_BASE64',
    'APP_STORE_CONNECT_KEY_ID',
    'APP_STORE_CONNECT_ISSUER_ID',
    'APP_STORE_CONNECT_PRIVATE_KEY',
  ];

  List<String> collect({
    required final ReleaseFacts facts,
    required final List<ReleasePlatform> platforms,
  }) => List.unmodifiable([
    if (facts.worktree == WorktreeState.dirty &&
        facts.dirtyPolicy == DirtyPolicy.forbid)
      'git worktree is dirty (commit, stash or pass --allow-dirty)',
    ...switch (facts.defines) {
      ReleaseDefinesUnavailable(:final reason) => ['env/release.json: $reason'],
      ReleaseDefinesLoaded(:final defines) =>
        defines
            .missingNonEmpty(
              keys: const ['NA_API_BASIC_AUTH', 'GOOGLE_MAPS_API_KEY'],
            )
            .map((final key) => 'env/release.json: $key is empty'),
    },
    ...switch (facts.pubspecVersion) {
      AppVersionUnparseable(:final reason) => ['app/pubspec.yaml: $reason'],
      AppVersionParsed(:final version) => switch (version.validate()) {
        AppVersionAccepted() => const <String>[],
        AppVersionRejected(:final reasons) => reasons.map(
          (final r) => 'app/pubspec.yaml: $r',
        ),
      },
    },
    ...platforms.expand(
      (final platform) => _platform(facts: facts, platform: platform),
    ),
  ]);

  Iterable<String> _platform({
    required final ReleaseFacts facts,
    required final ReleasePlatform platform,
  }) => switch (platform) {
    ReleasePlatform.android => [
      ..._missingSecrets(facts: facts, keys: androidSecrets),
      ..._missingTools(facts: facts, tools: const ['keytool', 'jarsigner']),
    ],
    ReleasePlatform.ios => [
      if (facts.hostOs != HostOs.macos) 'ios releases need macOS',
      ..._missingSecrets(facts: facts, keys: iosSecrets),
      ..._missingTools(facts: facts, tools: const ['xcodebuild']),
    ],
  };

  Iterable<String> _missingSecrets({
    required final ReleaseFacts facts,
    required final List<String> keys,
  }) => keys
      .where((final key) => (facts.environment[key] ?? '').trim().isEmpty)
      .map((final key) => 'environment variable $key is not set');

  Iterable<String> _missingTools({
    required final ReleaseFacts facts,
    required final List<String> tools,
  }) => tools
      .where((final tool) => !facts.toolsOnPath.contains(tool))
      .map((final tool) => '$tool is not on PATH');
}
