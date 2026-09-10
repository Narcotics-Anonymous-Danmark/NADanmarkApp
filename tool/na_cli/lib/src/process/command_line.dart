import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/executable.dart';

final class CommandLine {
  const CommandLine({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
  });

  const CommandLine.at({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  }) : environment = const {};

  final Executable executable;
  final List<String> arguments;
  final FilePath workingDirectory;
  final Map<String, String> environment;

  String get display => [executable.value, ...arguments].join(' ');
}
