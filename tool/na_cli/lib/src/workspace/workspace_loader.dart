import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';
import 'package:na_cli/src/workspace/workspace_members.dart';

final class WorkspaceLoader {
  const WorkspaceLoader({required this.context});

  final CliContext context;

  List<WorkspaceMember> members() {
    const parser = WorkspaceMembers();
    final rootText = _read(context.repoRoot.join('pubspec.yaml'));
    return List.unmodifiable(
      parser.memberDirectories(rootPubspecText: rootText).map((final dir) {
        final directory = context.repoRoot.join(dir);
        return WorkspaceMember(
          name: parser.nameOf(
            memberPubspecText: _read(directory.join('pubspec.yaml')),
            directory: directory,
          ),
          directory: directory,
        );
      }),
    );
  }

  String _read(final FilePath path) =>
      switch (context.files.readText(path: path)) {
        TextRead(:final text) => text,
        NoSuchFile() => '',
      };
}
