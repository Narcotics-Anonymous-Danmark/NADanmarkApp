import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/release/release_blockers.dart';
import 'package:na_cli/src/release/release_check.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:na_cli/src/release/version_store.dart';

final class ReleaseInputs {
  const ReleaseInputs({required this.context});

  final CliContext context;

  String secret({required final String key}) =>
      switch (context.environment.lookup(key: EnvKey(key))) {
        EnvSet(:final value) => value,
        EnvUnset() => throw CliFailure.general(message: '$key is not set'),
      };

  DartDefines defines() => switch (ReleaseCheck(context: context).defines()) {
    ReleaseDefinesLoaded(:final defines) => defines,
    ReleaseDefinesUnavailable(:final reason) => throw CliFailure.general(
      message: 'env/release.json: $reason',
    ),
  };

  AppVersion version() => VersionStore(context: context).read();

  String artifactName({
    required final AppVersion version,
    required final String extension,
  }) => 'nadanmark-${version.version}-${version.build.value}.$extension';
}
