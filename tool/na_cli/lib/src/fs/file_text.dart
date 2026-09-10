import 'package:na_cli/src/fs/file_path.dart';

sealed class FileText {
  const FileText();
}

final class TextRead extends FileText {
  const TextRead({required this.text});

  final String text;
}

final class NoSuchFile extends FileText {
  const NoSuchFile({required this.path});

  final FilePath path;
}
