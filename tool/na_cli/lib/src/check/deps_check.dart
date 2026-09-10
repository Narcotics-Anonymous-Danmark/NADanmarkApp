import 'package:na_cli/src/check/layer_rules.dart';
import 'package:na_cli/src/check/package_manifest.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/fs/path_status.dart';
import 'package:na_cli/src/process/exit_code.dart';
import 'package:na_cli/src/text/console_table.dart';
import 'package:na_cli/src/workspace/workspace_loader.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class DepsCheck {
  const DepsCheck({required this.context});

  final CliContext context;

  ExitCode run() {
    final members = WorkspaceLoader(context: context).members();
    final manifests = members.expand(_manifest).toList(growable: false);
    final violations = const LayerRules().violations(manifests: manifests);
    if (violations.isEmpty) {
      context.console.out(
        line: 'deps: ${manifests.length} packages respect the layers',
      );
      return ExitCode.success;
    }
    context.console.err(
      line: ConsoleTable(
        headers: const ['Package', 'Violation'],
        rows: violations
            .map((final v) => [v.package.value, v.reason])
            .toList(growable: false),
      ).render(),
    );
    return ExitCode.failure;
  }

  List<PackageManifest> _manifest(final WorkspaceMember member) {
    final text = switch (context.files.readText(path: member.pubspecPath)) {
      TextRead(:final text) => text,
      NoSuchFile() => '',
    };
    final lock = switch (context.files.status(
      path: member.directory.join('pubspec.lock'),
    )) {
      PathStatus.file => LockFilePresence.present,
      PathStatus.directory || PathStatus.missing => LockFilePresence.absent,
    };
    return switch (PackageManifest.parse(pubspecText: text, lockFile: lock)) {
      PackageManifestParsed(:final manifest) => [manifest],
      PackageManifestRejected(:final reason) => throw StateError(
        '${member.pubspecPath.value}: $reason',
      ),
    };
  }
}
