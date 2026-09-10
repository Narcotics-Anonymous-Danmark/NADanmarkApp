import 'dart:io';

import 'package:na_cli/src/fs/file_bytes.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/ports/file_system.dart';

final class IoFileSystem implements FileSystem {
  const IoFileSystem();

  @override
  PathStatus status({required final FilePath path}) {
    if (File(path.value).existsSync()) {
      return PathStatus.file;
    }
    if (Directory(path.value).existsSync()) {
      return PathStatus.directory;
    }
    return PathStatus.missing;
  }

  @override
  FileText readText({required final FilePath path}) {
    final file = File(path.value);
    if (file.existsSync()) {
      return TextRead(text: file.readAsStringSync());
    }
    return NoSuchFile(path: path);
  }

  @override
  FileBytes readBytes({required final FilePath path}) {
    final file = File(path.value);
    if (file.existsSync()) {
      return BytesRead(bytes: file.readAsBytesSync());
    }
    return NoSuchBinary(path: path);
  }

  @override
  void writeText({required final FilePath path, required final String text}) {
    File(path.value)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  @override
  void appendText({required final FilePath path, required final String text}) {
    File(path.value)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text, mode: FileMode.append);
  }

  @override
  void writeBytes({
    required final FilePath path,
    required final List<int> bytes,
  }) {
    File(path.value)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }

  @override
  void ensureDirectory({required final FilePath path}) {
    Directory(path.value).createSync(recursive: true);
  }

  @override
  void deleteTree({required final FilePath path}) {
    switch (status(path: path)) {
      case PathStatus.file:
        File(path.value).deleteSync();
      case PathStatus.directory:
        Directory(path.value).deleteSync(recursive: true);
      case PathStatus.missing:
        return;
    }
  }

  @override
  void copyFile({required final FilePath from, required final FilePath to}) {
    Directory(to.parent.value).createSync(recursive: true);
    File(from.value).copySync(to.value);
  }

  @override
  List<FilePath> entries({required final FilePath directory}) {
    final dir = Directory(directory.value);
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync()
        .map((final entity) => FilePath(entity.path))
        .toList(growable: false);
  }

  @override
  FilePath get homeDirectory =>
      FilePath(Platform.environment['HOME'] ?? Directory.current.path);
}
