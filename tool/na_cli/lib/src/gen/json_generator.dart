import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/workspace/workspace_loader.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class JsonGenerator {
  const JsonGenerator({required this.context});

  static const String builder = 'build_runner';

  final CliContext context;

  Future<void> generate() async {
    for (final member in _membersWithBuilder()) {
      await Shell(context: context).passThroughOrFail(
        command: CommandLine.at(
          executable: const Executable('dart'),
          arguments: const [
            'run',
            builder,
            'build',
            '--delete-conflicting-outputs',
          ],
          workingDirectory: member.directory,
        ),
      );
    }
  }

  List<WorkspaceMember> _membersWithBuilder() => List.unmodifiable(
    WorkspaceLoader(context: context).members().where(
      (final member) =>
          switch (context.files.readText(path: member.pubspecPath)) {
            TextRead(:final text) => switch (PackageManifest.parse(
              pubspecText: text,
              lockFile: LockFilePresence.absent,
            )) {
              PackageManifestParsed(:final manifest) =>
                manifest.devDependencies.contains(builder),
              PackageManifestRejected() => false,
            },
            NoSuchFile() => false,
          },
    ),
  );
}
