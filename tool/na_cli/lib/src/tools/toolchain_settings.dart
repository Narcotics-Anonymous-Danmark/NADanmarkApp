import 'package:na_cli/src/boundary/json_object.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/tools/env_file.dart';

final class ToolchainSettings {
  const ToolchainSettings({
    required this.values,
    required this.androidHome,
    required this.cmdlineTools,
    required this.flutterVersion,
  });

  factory ToolchainSettings.load({required final CliContext context}) {
    final fileValues = switch (context.files.readText(
      path: context.repoRoot.joinAll(['tool', 'toolchain.env']),
    )) {
      TextRead(:final text) => const EnvFile().parse(text: text),
      NoSuchFile() => const <String, String>{},
    };
    final merged = Map<String, String>.unmodifiable({
      for (final entry in fileValues.entries)
        entry.key: switch (context.environment.lookup(
          key: EnvKey(entry.key),
        )) {
          EnvSet(:final value) => value,
          EnvUnset() => entry.value,
        },
    });
    final androidHome = _androidHome(context);
    return ToolchainSettings(
      values: merged,
      androidHome: androidHome,
      cmdlineTools: _cmdlineTools(context, androidHome: androidHome),
      flutterVersion: _flutterVersion(context),
    );
  }

  final Map<String, String> values;
  final FilePath androidHome;
  final FilePath cmdlineTools;
  final String flutterVersion;

  static FilePath _cmdlineTools(
    final CliContext context, {
    required final FilePath androidHome,
  }) {
    final parent = androidHome.join('cmdline-tools');
    final latest = parent.join('latest');
    final installed = [latest, ...context.files.entries(directory: parent)]
        .where(
          (final dir) =>
              context.files.status(path: dir.joinAll(['bin', 'sdkmanager'])) ==
              PathStatus.file,
        );
    return installed.isEmpty ? latest : installed.first;
  }

  static String _flutterVersion(final CliContext context) =>
      switch (context.files.readText(path: context.repoRoot.join('.fvmrc'))) {
        TextRead(:final text) => switch (JsonObject.parse(text: text)) {
          JsonObjectParsed(:final object) =>
            object.text(key: 'flutter').orElse(fallback: ''),
          JsonListParsed() || JsonMalformed() => '',
        },
        NoSuchFile() => '',
      };

  static FilePath _androidHome(final CliContext context) {
    final fromEnv = [
      'ANDROID_HOME',
      'ANDROID_SDK_ROOT',
    ].map((final key) => context.environment.lookup(key: EnvKey(key)));
    final set = fromEnv.whereType<EnvSet>();
    if (set.isNotEmpty) {
      return FilePath(set.first.value);
    }
    return context.files.homeDirectory.joinAll(['Android', 'Sdk']);
  }

  String get cmdlineToolsVersion => _get('ANDROID_CMDLINE_TOOLS_VERSION');

  String get cmdlineToolsPackage => _get('ANDROID_CMDLINE_TOOLS_PACKAGE');

  String get androidPlatform => _get('ANDROID_PLATFORM');

  String get androidBuildTools => _get('ANDROID_BUILD_TOOLS');

  String get androidSystemImage => _get('ANDROID_SYSTEM_IMAGE');

  String get avdName => _get('ANDROID_AVD_NAME');

  String get avdDevice => _get('ANDROID_AVD_DEVICE');

  String get iosSimulatorName => _get('IOS_SIMULATOR_NAME');

  String get iosSimulatorDeviceType => _get('IOS_SIMULATOR_DEVICE_TYPE');

  int get xcodeMinimumMajor => int.parse(_get('XCODE_MINIMUM_MAJOR'));

  String get patrolCliVersion => _get('PATROL_CLI_VERSION');

  String get javaVersion => _get('JAVA_VERSION');

  FilePath get sdkManager => cmdlineTools.joinAll(['bin', 'sdkmanager']);

  FilePath get avdManager => cmdlineTools.joinAll(['bin', 'avdmanager']);

  FilePath get emulator => androidHome.joinAll(['emulator', 'emulator']);

  FilePath get adb => androidHome.joinAll(['platform-tools', 'adb']);

  String _get(final String key) => values[key] ?? '';
}
