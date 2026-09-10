import 'package:na_cli/src/boundary/yaml_view.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class WorkspaceMembers {
  const WorkspaceMembers();

  List<String> memberDirectories({required final String rootPubspecText}) =>
      switch (YamlView.parse(text: rootPubspecText)) {
        YamlParsed(:final view) => view.stringList(key: 'workspace'),
        YamlMalformed() => const [],
      };

  PackageName nameOf({
    required final String memberPubspecText,
    required final FilePath directory,
  }) => switch (YamlView.parse(text: memberPubspecText)) {
    YamlParsed(:final view) => PackageName(
      view.text(key: 'name').orElse(fallback: directory.basename),
    ),
    YamlMalformed() => PackageName(directory.basename),
  };
}
