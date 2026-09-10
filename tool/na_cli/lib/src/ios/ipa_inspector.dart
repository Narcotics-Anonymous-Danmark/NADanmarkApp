import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/ios/ipa_verification.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:na_cli/src/tools/shell.dart';

final class IpaInspector {
  const IpaInspector({required this.context});

  final CliContext context;

  FilePath find() {
    final ipaDir = context.appDir.joinAll(['build', 'ios', 'ipa']);
    final ipas = context.files
        .entries(directory: ipaDir)
        .where((final entry) => entry.extension == '.ipa');
    if (ipas.isEmpty) {
      throw CliFailure.general(message: 'no .ipa found in ${ipaDir.value}');
    }
    return ipas.first;
  }

  Future<void> verify({
    required final FilePath ipa,
    required final AppVersion version,
    required final FilePath scratch,
  }) async {
    final shell = Shell(context: context);
    final unpacked = scratch.join('ipa');
    await shell.captureOrFail(
      command: CommandLine.at(
        executable: const Executable('unzip'),
        arguments: ['-q', '-o', ipa.value, 'Payload/*', '-d', unpacked.value],
        workingDirectory: context.repoRoot,
      ),
    );
    final apps = context.files
        .entries(directory: unpacked.join('Payload'))
        .where((final entry) => entry.extension == '.app');
    if (apps.isEmpty) {
      throw const CliFailure.general(message: 'ipa has no Payload/*.app');
    }
    final app = apps.first;
    Future<String> plist({required final String key}) => shell.captureOrFail(
      command: CommandLine.at(
        executable: const Executable('/usr/libexec/PlistBuddy'),
        arguments: ['-c', 'Print $key', app.join('Info.plist').value],
        workingDirectory: context.repoRoot,
      ),
    );
    final facts = IpaFacts(
      shortVersion: await plist(key: 'CFBundleShortVersionString'),
      bundleVersion: await plist(key: 'CFBundleVersion'),
      codeResourcesPresent: switch (context.files.status(
        path: app.joinAll(['_CodeSignature', 'CodeResources']),
      )) {
        PathStatus.file => CodeResources.present,
        PathStatus.directory || PathStatus.missing => CodeResources.missing,
      },
    );
    final problems = const IpaVerification().problems(
      facts: facts,
      expected: version,
    );
    if (problems.isNotEmpty) {
      throw CliFailure.general(message: problems.join('\n'));
    }
  }
}
