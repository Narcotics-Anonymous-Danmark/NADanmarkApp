import 'package:na_cli/src/fs/file_path.dart';

extension type const PackageName(String value) {}

final class WorkspaceMember {
  const WorkspaceMember({required this.name, required this.directory});

  final PackageName name;
  final FilePath directory;

  FilePath get libDirectory => directory.join('lib');

  FilePath get testDirectory => directory.join('test');

  FilePath get pubspecPath => directory.join('pubspec.yaml');
}
