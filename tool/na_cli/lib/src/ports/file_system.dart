import 'package:na_cli/src/fs/file_bytes.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';

abstract interface class FileSystem {
  PathStatus status({required FilePath path});

  FileText readText({required FilePath path});

  FileBytes readBytes({required FilePath path});

  void writeText({required FilePath path, required String text});

  void appendText({required FilePath path, required String text});

  void writeBytes({required FilePath path, required List<int> bytes});

  void ensureDirectory({required FilePath path});

  void deleteTree({required FilePath path});

  void copyFile({required FilePath from, required FilePath to});

  List<FilePath> entries({required FilePath directory});

  FilePath get homeDirectory;
}
