@Tags(['unit'])
library;

import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/release/release_blockers.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  ReleaseFacts facts({
    final WorktreeState worktree = WorktreeState.clean,
    final DirtyPolicy policy = DirtyPolicy.forbid,
    final Map<String, String> defines = const {
      'NA_API_BASIC_AUTH': 'u:p',
      'GOOGLE_MAPS_API_KEY': 'key',
    },
    final Map<String, String> environment = const {
      'ANDROID_KEYSTORE_BASE64': 'a',
      'ANDROID_KEYSTORE_PASSWORD': 'b',
      'ANDROID_KEY_PASSWORD': 'c',
    },
    final Set<String> tools = const {'keytool', 'jarsigner'},
    final HostOs hostOs = HostOs.linux,
  }) => ReleaseFacts(
    worktree: worktree,
    dirtyPolicy: policy,
    defines: ReleaseDefinesLoaded(defines: DartDefines(values: defines)),
    pubspecVersion: AppVersionParsed(version: anAppVersion()),
    environment: environment,
    toolsOnPath: tools,
    hostOs: hostOs,
  );

  const blockers = ReleaseBlockers();

  test('a ready android release has no blockers', () {
    expect(
      blockers.collect(
        facts: facts(),
        platforms: const [ReleasePlatform.android],
      ),
      isEmpty,
    );
  });

  test('collects every blocker instead of stopping at the first', () {
    final found = blockers.collect(
      facts: facts(
        worktree: WorktreeState.dirty,
        defines: const {'NA_API_BASIC_AUTH': '', 'GOOGLE_MAPS_API_KEY': ''},
        environment: const {},
        tools: const {},
      ),
      platforms: const [ReleasePlatform.android],
    );
    expect(found, hasLength(1 + 2 + 3 + 2));
  });

  test('--allow-dirty waives the clean worktree requirement', () {
    expect(
      blockers.collect(
        facts: facts(worktree: WorktreeState.dirty, policy: DirtyPolicy.allow),
        platforms: const [ReleasePlatform.android],
      ),
      isEmpty,
    );
  });

  test('ios needs macOS, xcodebuild and the App Store secrets', () {
    final found = blockers.collect(
      facts: facts(environment: const {}, tools: const {}),
      platforms: const [ReleasePlatform.ios],
    );
    expect(found.first, 'ios releases need macOS');
    expect(found, hasLength(1 + ReleaseBlockers.iosSecrets.length + 1));
  });

  test('a missing release.json is one blocker', () {
    final found = blockers.collect(
      facts: const ReleaseFacts(
        worktree: WorktreeState.clean,
        dirtyPolicy: DirtyPolicy.forbid,
        defines: ReleaseDefinesUnavailable(reason: 'file missing'),
        pubspecVersion: AppVersionUnparseable(reason: 'no version'),
        environment: {},
        toolsOnPath: {},
        hostOs: HostOs.linux,
      ),
      platforms: const [],
    );
    expect(found, [
      'env/release.json: file missing',
      'app/pubspec.yaml: no version',
    ]);
  });
}
