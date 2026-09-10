import 'dart:convert';

import 'package:na_cli/src/android/key_alias.dart';
import 'package:na_cli/src/android/key_properties.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/release/release_check.dart';
import 'package:na_cli/src/release/release_inputs.dart';
import 'package:na_cli/src/release/release_options.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/tools/shell.dart';

final class AndroidRelease {
  const AndroidRelease({required this.context});

  final CliContext context;

  Future<void> build({required final ReleaseOptions options}) async {
    await ReleaseCheck(context: context).assertReady(
      platforms: const [ReleasePlatform.android],
      dirtyPolicy: options.dirtyPolicy,
    );
    final inputs = ReleaseInputs(context: context);
    final version = inputs.version();
    final defines = inputs.defines();
    final scratch = context.releaseScratchDir;
    final keystore = scratch.join('upload.keystore');
    final properties = KeyProperties(
      storeFile: keystore,
      storePassword: inputs.secret(key: 'ANDROID_KEYSTORE_PASSWORD'),
      keyAlias: _alias(),
      keyPassword: inputs.secret(key: 'ANDROID_KEY_PASSWORD'),
    );
    final shell = Shell(context: context);
    final buildCommand = CommandLine(
      executable: const Executable('flutter'),
      arguments: [
        'build',
        'appbundle',
        '--release',
        '--dart-define-from-file=../env/release.json',
        '--build-name',
        '${version.version}',
        '--build-number',
        '${version.code.value}',
      ],
      workingDirectory: context.appDir,
      environment: {
        ...defines.childEnvironment,
        'NA_KEY_PROPERTIES': scratch.join('key.properties').value,
      },
    );
    final artifact = context.appDir.joinAll([
      'build',
      'app',
      'outputs',
      'bundle',
      'release',
      'app-release.aab',
    ]);
    final destination = options.outputDir.join(
      inputs.artifactName(version: version, extension: 'aab'),
    );
    switch (options.execution) {
      case BuildExecution.dryRun:
        context.console.out(line: 'dry-run: ${buildCommand.display}');
        context.console.out(line: 'dry-run: would write ${destination.value}');
        return;
      case BuildExecution.real:
        break;
    }
    try {
      context.files.ensureDirectory(path: scratch);
      await shell.captureOrFail(
        command: CommandLine.at(
          executable: const Executable('chmod'),
          arguments: ['700', scratch.value],
          workingDirectory: context.repoRoot,
        ),
      );
      context.files.writeBytes(
        path: keystore,
        bytes: base64Decode(
          inputs
              .secret(key: 'ANDROID_KEYSTORE_BASE64')
              .replaceAll(RegExp(r'\s'), ''),
        ),
      );
      context.files.writeText(
        path: scratch.join('key.properties'),
        text: properties.render(),
      );
      await shell.captureOrFail(
        command: CommandLine.at(
          executable: const Executable('chmod'),
          arguments: [
            '600',
            keystore.value,
            scratch.join('key.properties').value,
          ],
          workingDirectory: context.repoRoot,
        ),
      );
      await shell.captureOrFail(
        command: CommandLine.at(
          executable: const Executable('keytool'),
          arguments: [
            '-list',
            '-keystore',
            keystore.value,
            '-storepass',
            properties.storePassword,
            '-alias',
            properties.keyAlias.value,
          ],
          workingDirectory: context.repoRoot,
        ),
      );
      await shell.passThroughOrFail(command: buildCommand);
      final verification = await shell.captureOrFail(
        command: CommandLine.at(
          executable: const Executable('jarsigner'),
          arguments: ['-verify', '-verbose', artifact.value],
          workingDirectory: context.repoRoot,
        ),
      );
      if (!verification.contains('jar verified')) {
        throw const CliFailure.general(
          message: 'jarsigner did not report "jar verified"',
        );
      }
      context.files.copyFile(from: artifact, to: destination);
      context.console.out(line: 'wrote ${destination.value}');
    } finally {
      context.files.deleteTree(path: scratch);
    }
  }

  KeyAlias _alias() => switch (context.environment.lookup(
    key: const EnvKey('ANDROID_KEY_ALIAS'),
  )) {
    EnvSet(:final value) => ProvidedAlias(alias: value),
    EnvUnset() => const ConventionalAlias(),
  };
}
