import 'package:na_cli/src/coverage/lcov_document.dart';
import 'package:na_cli/src/coverage/lcov_record.dart';
import 'package:na_cli/src/fs/file_path.dart';

final class LcovPathRewriter {
  const LcovPathRewriter({required this.repoRoot});

  final FilePath repoRoot;

  LcovDocument rewrite({
    required final LcovDocument document,
    required final FilePath packageDirectory,
  }) => document.mapRecords(
    transform: (final record) => record.relocated(
      to: SourceFile(
        _repoRelative(
          file: FilePath(record.file.value),
          packageDirectory: packageDirectory,
        ),
      ),
    ),
  );

  String _repoRelative({
    required final FilePath file,
    required final FilePath packageDirectory,
  }) {
    final absolute = switch (file.shape) {
      PathShape.absolute => file,
      PathShape.relative => file.resolveFrom(packageDirectory),
    };
    return switch (absolute.containment(root: repoRoot)) {
      PathContainment.inside => absolute.relativeTo(repoRoot),
      PathContainment.outside => absolute.value,
    };
  }
}
