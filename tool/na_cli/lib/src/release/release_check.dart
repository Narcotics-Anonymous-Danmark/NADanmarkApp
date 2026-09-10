import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/env/dart_defines.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/release/pubspec_version.dart';
import 'package:na_cli/src/release/release_blockers.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/tool_presence.dart';

final class ReleaseCheck {
  const ReleaseCheck({required this.context});

  final CliContext context;

  Future<ReleaseFacts> facts({required final DirtyPolicy dirtyPolicy}) async {
    final shell = Shell(context: context);
    final status = await shell.capture(
      command: CommandLine.at(
        executable: const Executable('git'),
        arguments: const ['status', '--porcelain'],
        workingDirectory: context.repoRoot,
      ),
    );
    final tools = <String>[
      'keytool',
      'jarsigner',
      'xcodebuild',
      'security',
      'xcrun',
    ];
    final found = <String>{};
    for (final tool in tools) {
      switch (await shell.locate(executable: Executable(tool))) {
        case ToolFound():
          found.add(tool);
        case ToolMissing():
          break;
      }
    }
    final secrets = {
      ...ReleaseBlockers.androidSecrets,
      ...ReleaseBlockers.iosSecrets,
    };
    return ReleaseFacts(
      worktree: switch (status) {
        ProcessSucceeded(:final stdout) =>
          stdout.trim().isEmpty ? WorktreeState.clean : WorktreeState.dirty,
        ProcessFailed() || ProcessUnavailable() => WorktreeState.dirty,
      },
      dirtyPolicy: dirtyPolicy,
      defines: defines(),
      pubspecVersion: const PubspecVersion().read(
        pubspecText: switch (context.files.readText(
          path: context.appDir.join('pubspec.yaml'),
        )) {
          TextRead(:final text) => text,
          NoSuchFile() => '',
        },
      ),
      environment: Map.unmodifiable({
        for (final key in secrets)
          key: context.environment
              .lookup(key: EnvKey(key))
              .orElse(fallback: ''),
      }),
      toolsOnPath: Set.unmodifiable(found),
      hostOs: context.hostOs,
    );
  }

  ReleaseDefines defines() => switch (context.files.readText(
    path: context.envDir.join('release.json'),
  )) {
    NoSuchFile() => const ReleaseDefinesUnavailable(reason: 'file missing'),
    TextRead(:final text) => switch (DartDefines.parse(json: text)) {
      DartDefinesRejected(:final reason) => ReleaseDefinesUnavailable(
        reason: reason,
      ),
      DartDefinesParsed(:final defines) => ReleaseDefinesLoaded(
        defines: defines,
      ),
    },
  };

  Future<void> assertReady({
    required final List<ReleasePlatform> platforms,
    required final DirtyPolicy dirtyPolicy,
  }) async {
    final blockers = const ReleaseBlockers().collect(
      facts: await facts(dirtyPolicy: dirtyPolicy),
      platforms: platforms,
    );
    if (blockers.isNotEmpty) {
      throw CliFailure.general(
        message: [
          'release blocked:',
          ...blockers.map((final b) => '  - $b'),
        ].join('\n'),
      );
    }
    context.console.out(
      line:
          'release check ok for '
          '${platforms.map((final p) => p.name).join(', ')}',
    );
  }
}
