import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/release/release_blockers.dart';

enum BuildExecution { real, dryRun }

final class ReleaseOptions {
  const ReleaseOptions({
    required this.dirtyPolicy,
    required this.execution,
    required this.outputDir,
  });

  final DirtyPolicy dirtyPolicy;
  final BuildExecution execution;
  final FilePath outputDir;
}
