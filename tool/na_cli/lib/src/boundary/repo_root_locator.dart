import 'dart:io';

import 'package:na_cli/src/fs/file_path.dart';

final class RepoRootLocator {
  const RepoRootLocator();

  FilePath locate() {
    var candidate = Directory.current;
    while (true) {
      final pubspec = File('${candidate.path}/pubspec.yaml');
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('\nworkspace:')) {
        return FilePath(candidate.path);
      }
      final parent = candidate.parent;
      if (parent.path == candidate.path) {
        return FilePath(Directory.current.path);
      }
      candidate = parent;
    }
  }
}
