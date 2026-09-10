import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/executable.dart';

sealed class ToolPresence {
  const ToolPresence();
}

final class ToolFound extends ToolPresence {
  const ToolFound({required this.path});

  final FilePath path;
}

final class ToolMissing extends ToolPresence {
  const ToolMissing({required this.executable});

  final Executable executable;
}
