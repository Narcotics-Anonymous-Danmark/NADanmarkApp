import 'dart:convert';

import 'package:na_cli/src/fs/file_bytes.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/ports/file_system.dart';

final class FileSystemMimic implements FileSystem {
  FileSystemMimic({
    final Map<String, String> files = const {},
    final Set<String> directories = const {},
    final String home = '/home/tester',
  }) : _files = {
         for (final entry in files.entries) entry.key: utf8.encode(entry.value),
       },
       _directories = {...directories},
       _home = home;

  final Map<String, List<int>> _files;
  final Set<String> _directories;
  final String _home;
  final List<String> deleted = [];

  Map<String, String> get texts => {
    for (final entry in _files.entries) entry.key: utf8.decode(entry.value),
  };

  @override
  PathStatus status({required final FilePath path}) {
    if (_files.containsKey(path.value)) {
      return PathStatus.file;
    }
    if (_directories.contains(path.value) ||
        _files.keys.any((final f) => f.startsWith('${path.value}/'))) {
      return PathStatus.directory;
    }
    return PathStatus.missing;
  }

  @override
  FileText readText({required final FilePath path}) {
    final bytes = _files[path.value];
    return bytes == null
        ? NoSuchFile(path: path)
        : TextRead(text: utf8.decode(bytes));
  }

  @override
  FileBytes readBytes({required final FilePath path}) {
    final bytes = _files[path.value];
    return bytes == null ? NoSuchBinary(path: path) : BytesRead(bytes: bytes);
  }

  @override
  void writeText({required final FilePath path, required final String text}) {
    _files[path.value] = utf8.encode(text);
  }

  @override
  void appendText({required final FilePath path, required final String text}) {
    _files[path.value] = [...?_files[path.value], ...utf8.encode(text)];
  }

  @override
  void writeBytes({
    required final FilePath path,
    required final List<int> bytes,
  }) {
    _files[path.value] = bytes;
  }

  @override
  void ensureDirectory({required final FilePath path}) {
    _directories.add(path.value);
  }

  @override
  void deleteTree({required final FilePath path}) {
    deleted.add(path.value);
    _files.removeWhere(
      (final key, final _) =>
          key == path.value || key.startsWith('${path.value}/'),
    );
    _directories.remove(path.value);
  }

  @override
  void copyFile({required final FilePath from, required final FilePath to}) {
    _files[to.value] = [...?_files[from.value]];
  }

  @override
  List<FilePath> entries({required final FilePath directory}) => _files.keys
      .where((final key) => key.startsWith('${directory.value}/'))
      .map(
        (final key) =>
            '${directory.value}/'
            '${key.substring(directory.value.length + 1).split('/').first}',
      )
      .toSet()
      .map(FilePath.new)
      .toList();

  @override
  FilePath get homeDirectory => FilePath(_home);
}
