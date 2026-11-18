import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_parser.dart';
import 'package:na_cli/src/coverage/lcov_path_rewriter.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/workspace/workspace_member.dart';

final class CoverageMerge {
  const CoverageMerge({required this.context});

  final CliContext context;

  static const String mergedName = 'merged.lcov.info';

  LcovDocument merge({required final List<WorkspaceMember> members}) {
    final rewriter = LcovPathRewriter(repoRoot: context.repoRoot);
    final inputs = context.files
        .entries(directory: context.coverageDir)
        .where((final path) => path.value.endsWith('.lcov.info'))
        .where((final path) => path.basename != mergedName)
        .map(
          (final path) => rewriter.rewrite(
            document: const LcovParser().parse(text: _read(path)),
            packageDirectory: _packageDirectoryFor(
              lcov: path,
              members: members,
            ),
          ),
        )
        .toList(growable: false);
    return LcovDocument.merge(documents: inputs);
  }

  FilePath _packageDirectoryFor({
    required final FilePath lcov,
    required final List<WorkspaceMember> members,
  }) {
    final packageName = lcov.basename.split('.').first;
    final owners = members.where((final m) => m.name.value == packageName);
    return owners.isEmpty ? context.appDir : owners.first.directory;
  }

  String _read(final FilePath path) =>
      switch (context.files.readText(path: path)) {
        TextRead(:final text) => text,
        NoSuchFile() => '',
      };
}
