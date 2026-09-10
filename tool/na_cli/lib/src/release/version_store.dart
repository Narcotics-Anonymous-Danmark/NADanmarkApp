import 'dart:convert';

import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/release/pubspec_version.dart';
import 'package:na_cli/src/release/version.dart';

final class VersionStore {
  const VersionStore({required this.context});

  final CliContext context;

  FilePath get _pubspec => context.appDir.join('pubspec.yaml');

  String _text() => switch (context.files.readText(path: _pubspec)) {
    TextRead(:final text) => text,
    NoSuchFile() => throw const CliFailure.general(
      message: 'app/pubspec.yaml not found',
    ),
  };

  AppVersion read() =>
      switch (const PubspecVersion().read(pubspecText: _text())) {
        AppVersionParsed(:final version) => version,
        AppVersionUnparseable(:final reason) => throw CliFailure.general(
          message: 'app/pubspec.yaml: $reason',
        ),
      };

  void write({required final AppVersion version}) => context.files.writeText(
    path: _pubspec,
    text: const PubspecVersion().write(pubspecText: _text(), version: version),
  );

  String describe({required final AppVersion version}) =>
      'version ${version.version} build ${version.build.value} '
      'code ${version.code.value} tag ${version.tag.value}';

  String json({required final AppVersion version}) => jsonEncode({
    'version': '${version.version}',
    'build': version.build.value,
    'versionCode': version.code.value,
    'tag': version.tag.value,
  });

  void appendGithubOutput({required final AppVersion version}) {
    switch (context.environment.lookup(key: const EnvKey('GITHUB_OUTPUT'))) {
      case EnvUnset():
        throw const CliFailure.general(
          message: r'--github-output needs $GITHUB_OUTPUT to be set',
        );
      case EnvSet(:final value):
        context.files.appendText(
          path: FilePath(value),
          text: [
            'version=${version.version}',
            'build=${version.build.value}',
            'version_code=${version.code.value}',
            'tag=${version.tag.value}',
            '',
          ].join('\n'),
        );
    }
  }
}
