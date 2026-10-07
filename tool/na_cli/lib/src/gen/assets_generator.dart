import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/tools/shell.dart';

final class AssetsGenerator {
  const AssetsGenerator({required this.context});

  final CliContext context;

  Future<void> generate() async {
    final appDir = context.repoRoot.join('app');
    final xcodeProject = appDir.joinAll([
      'ios',
      'Runner.xcodeproj',
      'project.pbxproj',
    ]);
    final xcodeProjectBefore = context.files.readText(path: xcodeProject);
    final shell = Shell(context: context);
    await shell.passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: const ['run', 'flutter_launcher_icons'],
        workingDirectory: appDir,
      ),
    );
    switch (xcodeProjectBefore) {
      case TextRead(:final text):
        context.files.writeText(path: xcodeProject, text: text);
      case NoSuchFile():
        break;
    }
    await shell.passThroughOrFail(
      command: CommandLine.at(
        executable: const Executable('dart'),
        arguments: const ['run', 'flutter_native_splash:create'],
        workingDirectory: appDir,
      ),
    );
  }
}
