@Tags(['unit'])
library;

import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/publish/publish_guard.dart';
import 'package:na_cli/src/text/console_table.dart';
import 'package:na_cli/src/tools/env_file.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';
import 'package:na_cli/src/workspace/workspace_members.dart';
import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/builders.dart';
import '../support/file_system_mimic.dart';
import '../support/simple_mimics.dart';

void main() {
  test('env file parser handles quotes and comments', () {
    final values = const EnvFile().parse(
      text: '# comment\nA=1\nB="two words"\nC=\'x\'\nBROKEN\n',
    );
    expect(values, {'A': '1', 'B': 'two words', 'C': 'x'});
  });

  test('toolchain settings prefer environment over the file', () {
    final context = aContext(
      files: FileSystemMimic(
        files: {
          '$testRoot/tool/toolchain.env':
              'ANDROID_AVD_NAME=file_avd\nPATROL_CLI_VERSION=4.7.0\n',
        },
      ),
      environment: const {
        'ANDROID_AVD_NAME': 'env_avd',
        'ANDROID_HOME': '/sdk',
      },
    );
    final settings = ToolchainSettings.load(context: context);
    expect(settings.avdName, 'env_avd');
    expect(settings.patrolCliVersion, '4.7.0');
    expect(
      settings.sdkManager.value,
      '/sdk/cmdline-tools/latest/bin/sdkmanager',
    );
  });

  test('android home falls back to ~/Android/Sdk', () {
    final settings = ToolchainSettings.load(context: aContext());
    expect(settings.androidHome.value, '/home/tester/Android/Sdk');
  });

  test('sdkmanager is found under any cmdline-tools folder, latest first', () {
    final legacy = ToolchainSettings.load(
      context: aContext(
        environment: const {'ANDROID_HOME': '/sdk'},
        files: FileSystemMimic(
          files: {'/sdk/cmdline-tools/tools/bin/sdkmanager': ''},
        ),
      ),
    );
    expect(legacy.sdkManager.value, '/sdk/cmdline-tools/tools/bin/sdkmanager');
    expect(legacy.avdManager.value, '/sdk/cmdline-tools/tools/bin/avdmanager');
    final both = ToolchainSettings.load(
      context: aContext(
        environment: const {'ANDROID_HOME': '/sdk'},
        files: FileSystemMimic(
          files: {
            '/sdk/cmdline-tools/tools/bin/sdkmanager': '',
            '/sdk/cmdline-tools/latest/bin/sdkmanager': '',
          },
        ),
      ),
    );
    expect(both.sdkManager.value, '/sdk/cmdline-tools/latest/bin/sdkmanager');
  });

  test('the flutter pin comes from .fvmrc and is empty without it', () {
    final pinned = ToolchainSettings.load(
      context: aContext(
        files: FileSystemMimic(
          files: {'$testRoot/.fvmrc': '{"flutter": "3.41.3"}'},
        ),
      ),
    );
    expect(pinned.flutterVersion, '3.41.3');
    expect(ToolchainSettings.load(context: aContext()).flutterVersion, '');
  });

  test('workspace members come from the root pubspec', () {
    const members = WorkspaceMembers();
    expect(
      members.memberDirectories(rootPubspecText: aRootPubspec()),
      ['app', 'packages/core/na_kernel'],
    );
    expect(members.memberDirectories(rootPubspecText: 'name: x'), isEmpty);
  });

  test('publish guard needs CI or --yes', () {
    const guard = PublishGuard();
    expect(
      guard.consent(environment: const EnvironmentMimic(), yes: FlagState.off),
      PublishConsent.withheld,
    );
    expect(
      guard.consent(
        environment: const EnvironmentMimic(values: {'CI': 'true'}),
        yes: FlagState.off,
      ),
      PublishConsent.granted,
    );
    expect(
      guard.consent(environment: const EnvironmentMimic(), yes: FlagState.on),
      PublishConsent.granted,
    );
  });

  test('console table pads columns', () {
    final text = const ConsoleTable(
      headers: ['A', 'Bee'],
      rows: [
        ['xx', 'y'],
      ],
    ).render();
    expect(text, 'A   Bee\n--  ---\nxx  y');
  });
}
