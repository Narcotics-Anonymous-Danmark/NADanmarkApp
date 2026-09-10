import 'package:na_cli/src/fs/file_path.dart';

sealed class FileBytes {
  const FileBytes();
}

final class BytesRead extends FileBytes {
  const BytesRead({required this.bytes});

  final List<int> bytes;
}

final class NoSuchBinary extends FileBytes {
  const NoSuchBinary({required this.path});

  final FilePath path;
}
