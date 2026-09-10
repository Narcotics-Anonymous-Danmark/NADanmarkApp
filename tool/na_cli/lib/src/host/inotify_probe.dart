import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/host/inotify_limits.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';

final class InotifyProbe {
  const InotifyProbe({required this.context});

  final CliContext context;

  Future<InotifyLimits> read() async {
    final inUse = await context.processes.capture(
      command: CommandLine.at(
        executable: const Executable('bash'),
        arguments: const [
          '-c',
          "find /proc/*/fd -lname 'anon_inode:inotify' 2>/dev/null | wc -l",
        ],
        workingDirectory: context.repoRoot,
      ),
    );
    return InotifyLimits(
      maxInstances: _number(
        const FilePath('/proc/sys/fs/inotify/max_user_instances'),
      ),
      instancesInUse: switch (inUse) {
        ProcessSucceeded(:final stdout) => int.tryParse(stdout.trim()) ?? 0,
        ProcessFailed() || ProcessUnavailable() => 0,
      },
      maxWatches: _number(
        const FilePath('/proc/sys/fs/inotify/max_user_watches'),
      ),
    );
  }

  int _number(final FilePath path) =>
      switch (context.files.readText(path: path)) {
        TextRead(:final text) => int.tryParse(text.trim()) ?? 0,
        NoSuchFile() => 0,
      };
}
